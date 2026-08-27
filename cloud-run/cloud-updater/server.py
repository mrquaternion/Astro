import json
import os
import shutil
import subprocess
import tempfile
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


PORT = int(os.environ.get("PORT", "8080"))
SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_BUCKET = os.environ.get("SUPABASE_STORAGE_BUCKET", "")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
UPDATE_SECRET = os.environ.get("UPDATE_SECRET", "")


def run(command):
    return subprocess.run(command, check=True, text=True, capture_output=True)


def download(url, destination):
    request = urllib.request.Request(url, headers={"User-Agent": "astro-cloud-updater/1.0"})
    with urllib.request.urlopen(request, timeout=120) as response, destination.open("wb") as output:
        shutil.copyfileobj(response, output)


def reproject(source, destination):
    with tempfile.TemporaryDirectory() as directory:
        georeferenced = Path(directory) / "source.tif"

        run([
            "gdal_translate",
            "-of", "GTiff",
            "-a_srs", "EPSG:4326",
            "-a_ullr", "-180", "90", "180", "-90",
            str(source),
            str(georeferenced),
        ])

        run([
            "gdalwarp",
            "-overwrite",
            "-s_srs", "EPSG:4326",
            "-t_srs", "EPSG:3857",
            "-te", "-20037508.342789244", "-20037508.342789244",
            "20037508.342789244", "20037508.342789244",
            "-ts", "8192", "4096",
            "-r", "bilinear",
            "-srcalpha",
            "-dstalpha",
            "-dstnodata", "255",
            "-of", "PNG",
            str(georeferenced),
            str(destination),
        ])


def upload_to_supabase(source, object_path):
    required = [SUPABASE_URL, SUPABASE_BUCKET, SUPABASE_SERVICE_ROLE_KEY]
    if not all(required):
        raise RuntimeError("Supabase environment variables are missing")

    url = f"{SUPABASE_URL}/storage/v1/object/{SUPABASE_BUCKET}/{object_path.lstrip('/')}"
    request = urllib.request.Request(
        url,
        data=source.read_bytes(),
        method="POST",
        headers={
            "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
            "apikey": SUPABASE_SERVICE_ROLE_KEY,
            "Content-Type": "image/png",
            "x-upsert": "true",
        },
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        if response.status not in (200, 201):
            raise RuntimeError(f"Supabase Storage returned HTTP {response.status}")


def process(payload):
    source_url = payload.get("source_url") or os.environ.get("SOURCE_URL")
    output_path = payload.get("output_path") or os.environ.get("OUTPUT_PATH", "latest.png")
    if not source_url:
        raise ValueError("source_url is required")

    with tempfile.TemporaryDirectory() as directory:
        directory = Path(directory)
        source = directory / "source.png"
        output = directory / "cloud-latest.png"
        download(source_url, source)
        reproject(source, output)
        upload_to_supabase(output, output_path)

    return {"status": "updated", "output_path": output_path}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
            return
        self.send_error(404)

    def do_POST(self):
        if self.path != "/update":
            self.send_error(404)
            return
        if UPDATE_SECRET and self.headers.get("X-Update-Secret") != UPDATE_SECRET:
            self.send_error(401)
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length) or b"{}")
            result = process(payload)
            body = json.dumps(result).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(body)
        except Exception as error:
            self.send_error(500, str(error))

    def log_message(self, format, *args):
        print(format % args, flush=True)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
