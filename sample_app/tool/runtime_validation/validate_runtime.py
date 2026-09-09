#!/usr/bin/env python3
"""Validate the Flutter probe result and native requests recorded by the mock."""

import argparse
import json
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple


RESULT_PREFIX = "APPSTACK_RUNTIME_RESULT:"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def read_requests(path: Path) -> List[Dict]:
    if not path.exists():
        return []
    requests = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            requests.append(json.loads(line))
        except json.JSONDecodeError:
            # A request may be in the middle of being flushed while polling.
            continue
    return requests


def required_events(
    requests: List[Dict],
) -> Tuple[List[Dict], Optional[Dict], Optional[Dict]]:
    events = [
        item["body"]
        for item in requests
        if item["path"].split("?", 1)[0].endswith("/events")
        and isinstance(item.get("body"), dict)
    ]
    custom = next(
        (
            event
            for event in events
            if event.get("event_name") == "runtime_validation_custom"
        ),
        None,
    )
    login = next(
        (event for event in events if event.get("event_name") == "LOGIN"), None
    )
    return events, custom, login


def link_case(result: Dict, label: str) -> Dict:
    for item in result.get("linkCases") or []:
        if item.get("label") == label:
            return item
    raise AssertionError(f"runtime probe recorded no link case {label!r}")


def validate_links(result: Dict) -> Dict[str, Optional[str]]:
    """Check the documented universal-link contract and return the observed
    behaviour of the cases the contract leaves open."""
    pre = result.get("preConfigureLink") or {}
    require(not pre.get("error"), f"link parse before configure() failed: {pre.get('error')}")
    require(
        pre.get("supported") is True,
        "link parsing must work before configure()",
    )
    require(
        pre.get("deeplinkId") == "pre123",
        f"wrong deeplink ID before configure(): {pre.get('deeplinkId')!r}",
    )

    branded = link_case(result, "brandedSingleSegment")
    require(not branded.get("error"), f"branded link threw: {branded.get('error')}")
    require(
        branded.get("supported") is True,
        "a branded host with one path segment must be supported",
    )
    require(
        branded.get("deeplinkId") == "abc123",
        f"wrong deeplink ID: {branded.get('deeplinkId')!r}",
    )
    query = branded.get("queryParams") or {}
    require(query.get("screen") == "offer", "query parameter lost on the bridge")
    require(
        query.get("utm_source") == "café 🚀",
        "percent-encoded UTF-8 query parameter changed on the bridge",
    )

    for label in (
        "sharedHost",
        "sharedDevHost",
        "multiSegment",
        "noSegment",
        "hostNotAllowed",
    ):
        item = link_case(result, label)
        require(not item.get("error"), f"{label} threw: {item.get('error')}")
        require(
            item.get("supported") is False,
            f"{label} must be unsupported but returned {item.get('deeplinkId')!r}",
        )

    # Not part of the documented contract; recorded so a behaviour change is
    # visible in the harness output rather than silently assumed.
    observed = {}
    for label in ("noAllowlistBranded", "noAllowlistShared", "customScheme"):
        item = link_case(result, label)
        observed[label] = (
            f"error: {item['error']}"
            if item.get("error")
            else (item.get("deeplinkId") if item.get("supported") else None)
        )
    return observed


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--runtime-log", required=True)
    parser.add_argument("--requests-file", required=True)
    parser.add_argument("--expected-wrapper-version", required=True)
    parser.add_argument("--timeout-seconds", type=float, default=15.0)
    args = parser.parse_args()

    runtime_log = Path(args.runtime_log).read_text(
        encoding="utf-8", errors="replace"
    )
    result_lines = [
        line for line in runtime_log.splitlines() if RESULT_PREFIX in line
    ]
    require(result_lines, "runtime log has no terminal validation result")
    result = json.loads(result_lines[-1].split(RESULT_PREFIX, 1)[1].strip())

    require(result.get("configured") is True, "wrapper configure did not complete")
    require(result.get("appstackIdPresent") is True, "native SDK returned no Appstack ID")
    require(result.get("sdkDisabled") is False, "native SDK reports disabled")
    require(
        result.get("attributionCompleted") is True,
        "wrapper attribution operations did not complete",
    )
    require(
        result.get("attributionValidated") is True,
        "attribution payload was corrupted",
    )
    require(
        result.get("customEventAccepted") is True,
        "custom event call did not complete successfully",
    )
    require(
        result.get("standardEventAccepted") is True,
        "standard event call did not complete successfully",
    )
    require(not result.get("errors"), f"runtime probe errors: {result.get('errors')}")

    observed_links = validate_links(result)

    requests_path = Path(args.requests_file)
    deadline = time.monotonic() + args.timeout_seconds
    requests: List[Dict] = []
    events: List[Dict] = []
    custom = None
    login = None
    while time.monotonic() < deadline:
        requests = read_requests(requests_path)
        events, custom, login = required_events(requests)
        has_config = any(
            item["path"].split("?", 1)[0].endswith("/config")
            for item in requests
        )
        has_match = any(
            "/attribution/match/" in item["path"] for item in requests
        )
        if has_config and has_match and custom is not None and login is not None:
            break
        time.sleep(0.25)

    require(
        any(
            item["path"].split("?", 1)[0].endswith("/config")
            for item in requests
        ),
        "native SDK did not fetch remote configuration",
    )
    require(
        any("/attribution/match/" in item["path"] for item in requests),
        "native SDK did not perform attribution matching",
    )
    require(custom is not None, "custom event never reached the native wire boundary")
    require(login is not None, "standard event never reached the native wire boundary")
    require(
        custom.get("wrapper_version") == args.expected_wrapper_version,
        "wrong wrapper version on custom event",
    )
    require(
        custom.get("customer_user_id") == "runtime-validation-user",
        "customer ID was not forwarded",
    )

    parameters = custom.get("custom_parameters") or {}
    require(parameters.get("number") == 42, "numeric custom parameter changed")
    require(parameters.get("boolean") is True, "boolean custom parameter changed")
    require(parameters.get("unicode") == "café 🚀", "UTF-8 custom parameter changed")
    require(
        parameters.get("items") == ["one", 2, False],
        "array custom parameter changed",
    )
    require(
        parameters.get("nested") == {"enabled": True, "value": 7},
        "nested custom parameter changed",
    )

    login_parameters = login.get("custom_parameters") or {}
    require(
        login_parameters.get("state") == "ready",
        "standard event string parameter changed",
    )
    require(
        login_parameters.get("sequence") == 2,
        "standard event numeric parameter changed",
    )

    print(
        json.dumps(
            {
                "platform": result.get("platform"),
                "eventsRecorded": len(events),
                "wrapperVersion": custom.get("wrapper_version"),
                "linkCasesChecked": len(result.get("linkCases") or []),
                "undocumentedLinkBehaviour": observed_links,
            },
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
