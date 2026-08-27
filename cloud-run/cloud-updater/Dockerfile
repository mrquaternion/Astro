FROM ghcr.io/osgeo/gdal:ubuntu-small-latest

WORKDIR /app
COPY server.py /app/server.py

ENV PORT=8080
EXPOSE 8080

CMD ["python3", "/app/server.py"]
