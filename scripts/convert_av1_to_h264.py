#!/usr/bin/env python3
"""
Script tải và convert toàn bộ 12 video AV1 sang H.264 (avc1) chuẩn Apple / Android.
Sau khi chạy xong, các file H.264 sẽ nằm trong thư mục 'converted_videos/'.
Bạn có thể upload các file này đè lên thư mục 'api/uploads/videos/' trên hosting.
"""

import os
import subprocess
import urllib.request

FFMPEG_PATH = "/tmp/node_modules/ffmpeg-static/ffmpeg"
OUTPUT_DIR = "/Users/tronghieu/Downloads/noiso_biensau/converted_videos"

VIDEOS = [
    "great_white_breach.mp4",
    "shark_frenzy_hunt.mp4",
    "deep_shadow_shark.mp4",
    "megalodon_strike.mp4",
    "mariana_predator.mp4",
    "orca_pack_assault.mp4",
    "titan_blue_whale.mp4",
    "leviathan_whale_breach.mp4",
    "abyssal_humpback_song.mp4",
    "antarctic_whale_drift.mp4",
    "whale_vortex_feeding.mp4",
    "deep_whale_encounter.mp4",
]

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs("/tmp/raw_videos", exist_ok=True)

    print(f"=== BẮT ĐẦU CHUYỂN ĐỔI {len(VIDEOS)} VIDEO SANG H.264 ===")
    
    for idx, name in enumerate(VIDEOS, 1):
        raw_url = f"https://codego.io.vn/api/uploads/videos/{name}"
        raw_path = f"/tmp/raw_videos/{name}"
        out_path = os.path.join(OUTPUT_DIR, name)

        if os.path.exists(out_path):
            print(f"[{idx}/{len(VIDEOS)}] Đã tồn tại: {name}")
            continue

        print(f"[{idx}/{len(VIDEOS)}] Đang tải: {name} ...")
        req = urllib.request.Request(raw_url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req) as resp, open(raw_path, "wb") as f:
            f.write(resp.read())

        print(f"[{idx}/{len(VIDEOS)}] Đang convert sang H.264 (avc1) ...")
        cmd = [
            FFMPEG_PATH,
            "-i", raw_path,
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-preset", "fast",
            "-crf", "22",
            "-c:a", "copy",
            "-movflags", "+faststart",
            out_path,
            "-y"
        ]
        res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if res.returncode == 0:
            sz_mb = os.path.getsize(out_path) / (1024 * 1024)
            print(f"[{idx}/{len(VIDEOS)}] ✅ HOÀN THÀNH: {name} ({sz_mb:.2f} MB)")
        else:
            print(f"[{idx}/{len(VIDEOS)}] ❌ LỖI convert {name}")

        if os.path.exists(raw_path):
            os.remove(raw_path)

    print("\n=== TẤT CẢ FILE ĐÃ ĐƯỢC CHUYỂN ĐỔI THÀNH CÔNG VÀO 'converted_videos/' ===")

if __name__ == "__main__":
    main()
