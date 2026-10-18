"""Reconcile only the explicitly configured desktop apps in the current GUI session."""

import fcntl
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import time


class ModeError(Exception):
    pass


def execute(arguments):
    return subprocess.run(arguments, text=True, capture_output=True, timeout=20)


def checked(arguments):
    result = execute(arguments)
    if result.returncode:
        raise ModeError(result.stderr.strip() or f"command failed: {arguments[0]}")
    return result.stdout.strip()


def job_status(target, domain):
    result = execute(["/bin/launchctl", "print", f"{domain}/{target['label']}"])
    if result.returncode:
        if "Could not find service" in result.stderr:
            return "unloaded"
        raise ModeError(result.stderr.strip() or "could not observe launchd job")
    return "running" if "state = running" in result.stdout else "loaded"


def application_status(target, helper, action="status"):
    return checked([
        "/usr/bin/osascript", "-l", "JavaScript", str(helper),
        target["bundleID"], action,
    ])


def wait_for(observe, expected, description):
    deadline = time.monotonic() + 15
    while True:
        if observe() == expected:
            return
        if time.monotonic() >= deadline:
            raise ModeError(f"timed out waiting for {description}")
        time.sleep(0.2)


def reconcile(target, mode, domain, helper):
    job = job_status(target, domain)
    application = application_status(target, helper)
    service = f"{domain}/{target['label']}"
    if mode == "desktop":
        if job == "unloaded":
            result = execute(["/bin/launchctl", "bootstrap", domain, target["plist"]])
            # Login can load the same plist between observation and bootstrap.
            if result.returncode and job_status(target, domain) == "unloaded":
                raise ModeError(result.stderr.strip() or "bootstrap failed")
            job = job_status(target, domain)
        # A manually started app must not overlap a newly started managed job.
        if job != "running" and application == "running":
            application_status(target, helper, "terminate")
            wait_for(lambda: application_status(target, helper), "stopped", "normal application exit before restart")
        if job != "running" or application != "running":
            checked(["/bin/launchctl", "kickstart", service])
        wait_for(lambda: application_status(target, helper), "running", "application startup")
        wait_for(lambda: job_status(target, domain), "running", "launchd job startup")
    else:
        if application == "running":
            application_status(target, helper, "terminate")
        wait_for(lambda: application_status(target, helper), "stopped", "normal application exit")
        if job != "unloaded":
            result = execute(["/bin/launchctl", "bootout", service])
            if result.returncode and job_status(target, domain) != "unloaded":
                raise ModeError(result.stderr.strip() or "bootout failed")
        wait_for(lambda: job_status(target, domain), "unloaded", "launchd job removal")
        # Stopping a launcher alone does not establish that its app has exited.
        wait_for(lambda: application_status(target, helper), "stopped", "application exit")


def save_mode(directory, mode):
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=directory, delete=False) as output:
            temporary = Path(output.name)
            output.write(mode + "\n")
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, directory / "mode")
        temporary = None
        descriptor = os.open(directory, os.O_RDONLY)
        try:
            os.fsync(descriptor)
        finally:
            os.close(descriptor)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main():
    if len(sys.argv) != 5 or sys.argv[4] not in {"desktop", "server", "status", "reconcile"}:
        print("usage: mac-mode desktop|server|status", file=sys.stderr)
        return 2
    directory, targets_path, helper = map(Path, sys.argv[1:4])
    action = sys.argv[4]
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    # Never unlink the lock: every entry point must lock the same inode.
    with (directory / "lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        mode_file = directory / "mode"
        mode = mode_file.read_text().strip() if mode_file.exists() else "desktop"
        if action in {"desktop", "server"}:
            mode = action
            save_mode(directory, mode)
        if mode not in {"desktop", "server"}:
            raise ModeError(f"invalid saved mode: {mode!r}")
        if action == "status":
            print(f"desired: {mode}")
        domain = f"gui/{os.getuid()}"
        checked(["/bin/launchctl", "print", domain])
        targets = json.loads(targets_path.read_text())
        failed = False
        for target in targets:
            try:
                with (Path(target["appPath"]) / "Contents/Info.plist").open("rb") as info:
                    target["bundleID"] = plistlib.load(info)["CFBundleIdentifier"]
                if action == "status":
                    job = job_status(target, domain)
                    application = application_status(target, helper)
                    print(f"{target['name']}: job={job} application={application}")
                else:
                    reconcile(target, mode, domain, helper)
                    print(f"{target['name']}: {mode}")
            except (ModeError, OSError, ValueError, KeyError, subprocess.TimeoutExpired) as error:
                print(f"{target['name']}: {error}", file=sys.stderr)
                failed = True
        return 1 if failed else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ModeError, OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(f"mac-mode: {error}", file=sys.stderr)
        sys.exit(1)
