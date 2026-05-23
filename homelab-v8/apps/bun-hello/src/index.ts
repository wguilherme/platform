const server = Bun.serve({
  port: 8080,
  fetch(req) {
    const url = new URL(req.url);
    if (url.pathname === "/health") {
      return new Response("ok");
    }
    return new Response(
      JSON.stringify({
        message: "Hello from Bun!",
        version: process.env.APP_VERSION ?? "dev",
        runtime: `Bun ${Bun.version}`,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  },
});

console.log(`Listening on http://localhost:${server.port}`);
