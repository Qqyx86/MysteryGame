"""Run the MysteryGame happy path against the connected HarmonyOS emulator."""

from __future__ import annotations

import json
import re
import subprocess
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HDC = Path(r"D:/deveco/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe")
PACKAGE = "com.qqyx.mysterygame"
LAYOUT_REMOTE = "/data/local/tmp/mystery_layout.json"
LAYOUT_LOCAL = ROOT / "tools" / ".runtime-layout.json"
SCREENSHOT_DIR = ROOT / "docs" / "screenshots"


def run_hdc(*args: str, timeout: int = 20) -> str:
    result = subprocess.run(
        [str(HDC), *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr or result.stdout)
    return result.stdout


def device_shell(command: str, timeout: int = 20) -> str:
    return run_hdc("shell", command, timeout=timeout)


def dump_layout() -> dict:
    device_shell(f"uitest dumpLayout -p {LAYOUT_REMOTE}")
    run_hdc("file", "recv", LAYOUT_REMOTE, str(LAYOUT_LOCAL))
    return json.loads(LAYOUT_LOCAL.read_text(encoding="utf-8"))


def walk_layout(node: object):
    if isinstance(node, dict):
        yield node
        for value in node.values():
            yield from walk_layout(value)
    elif isinstance(node, list):
        for value in node:
            yield from walk_layout(value)


def find_text(node: object, label: str) -> dict | None:
    matches = []
    for item in walk_layout(node):
        attributes = item.get("attributes", {})
        if attributes.get("text") == label:
            matches.append(item)
    if not matches:
        return None
    return max(matches, key=lambda item: _area(item.get("attributes", {}).get("bounds", "")))


def _bounds(value: str) -> tuple[int, int, int, int] | None:
    numbers = [int(number) for number in re.findall(r"-?\d+", value)]
    if len(numbers) != 4:
        return None
    return numbers[0], numbers[1], numbers[2], numbers[3]


def _area(value: str) -> int:
    bounds = _bounds(value)
    if bounds is None:
        return 0
    left, top, right, bottom = bounds
    return max(0, right - left) * max(0, bottom - top)


def click_text(label: str, max_swipes: int = 4, wait: float = 0.9) -> None:
    for attempt in range(max_swipes + 1):
        layout = dump_layout()
        target = find_text(layout, label)
        if target is not None:
            bounds = _bounds(target["attributes"]["bounds"])
            if bounds is not None:
                left, top, right, bottom = bounds
                x = (left + right) // 2
                y = (top + bottom) // 2
                device_shell(f"uitest uiInput click {x} {y}")
                time.sleep(wait)
                return
        if attempt < max_swipes:
            device_shell("uitest uiInput swipe 660 2200 660 780 700")
            time.sleep(0.45)
    raise RuntimeError(f"Unable to find UI label: {label}")


def screenshot(name: str) -> None:
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    remote = f"/data/local/tmp/{name}.jpeg"
    local = SCREENSHOT_DIR / f"{name}.jpeg"
    time.sleep(2.3)
    device_shell(f"snapshot_display -f {remote}")
    run_hdc("file", "recv", remote, str(local))


def restart_app() -> None:
    device_shell(f"aa force-stop {PACKAGE}")
    device_shell(f"aa start -a EntryAbility -b {PACKAGE}")
    time.sleep(2.2)


def start_fresh_case() -> None:
    restart_app()
    layout = dump_layout()
    if find_text(layout, "继续调查") is not None:
        screenshot("01-cover")
        click_text("重新立案", max_swipes=0)
        click_text("确认重开", max_swipes=0, wait=1.2)
    else:
        screenshot("01-cover")
        click_text("建立调查档案", max_swipes=0, wait=1.2)


def walk_happy_path() -> None:
    start_fresh_case()
    screenshot("02-library-event")

    click_text("接受委托")
    click_text("翻查借阅卡")
    click_text("用借阅卡无损开启")
    click_text("承诺保护证人")

    click_text("线索", max_swipes=0)
    screenshot("03-clue-board")
    click_text("调查", max_swipes=0)
    click_text("前往 北区实验楼")

    screenshot("04-lab-event")
    click_text("追踪离线门禁记录")
    click_text("从头听完完整录音")
    click_text("播放完整录音并等待解释")
    click_text("对比钟楼与实验楼线路")
    click_text("前往 停摆钟楼")

    screenshot("05-bell-tower-event")
    click_text("用并联电路时间窗读卡")
    click_text("保留现场并观察等待")
    click_text("按编号检查齿轮")
    click_text("修复触点并播放完整留言")
    click_text("用门禁卡打开维护门")
    click_text("封存现场，开始最终推理", wait=1.2)

    screenshot("06-final-deduction")
    click_text("周岚", max_swipes=1)
    click_text("保护事故证据", max_swipes=2)
    click_text("提交最终判断", max_swipes=2, wait=1.4)
    screenshot("07-truth-ending")

    restart_app()
    screenshot("08-restored-cover")
    click_text("继续调查", max_swipes=0, wait=1.3)
    screenshot("09-restored-ending")


def walk_echo_path() -> None:
    start_fresh_case()
    click_text("接受委托")
    click_text("直接寻找档案柜")
    click_text("强行撬开档案柜")
    click_text("拿破坏记录施压")
    click_text("前往 北区实验楼")
    click_text("从检修通道绕入")
    click_text("只提取最后一分钟")
    click_text("用残缺片段诈问")
    click_text("短接总闸逼出备用线路")
    click_text("前往 停摆钟楼")
    click_text("沿外墙检修梯攀爬")
    click_text("追上雨幕中的影子")
    click_text("直接短接电缆恢复控制室")
    click_text("依据现场静默判断")
    click_text("用门禁卡打开维护门")
    click_text("封存现场，开始最终推理", wait=1.2)
    click_text("林澈", max_swipes=1)
    click_text("保护事故证据", max_swipes=2)
    click_text("提交最终判断", max_swipes=2, wait=1.4)
    screenshot("10-echo-ending")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "echo":
        walk_echo_path()
    else:
        walk_happy_path()
    print("Walkthrough complete. Screenshots saved to", SCREENSHOT_DIR)
