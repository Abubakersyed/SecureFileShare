import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",   # accessible on your local network
        port=8000,
        reload=True        # auto-restarts when you edit code
    )
