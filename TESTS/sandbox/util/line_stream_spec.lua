--- `util.line_stream` turns a subprocess's stdout chunks into whole lines.
--- The two things it has to get right are the two that only show up under
--- real streaming: a line split across chunk boundaries, and the CR that
--- `vim.system`'s `text = true` does not strip for a function handler.

describe("util.line_stream", function()
  local line_stream = require("sandbox.util.line_stream")

  it("completes a line that arrives across two chunks", function()
    local s = line_stream.new()

    assert.are.same({}, s.feed("par"))
    assert.are.same({ "partial" }, s.feed("tial\n"))
    assert.are.same("", s.flush())
  end)

  it("returns every whole line in a chunk and buffers the rest", function()
    local s = line_stream.new()

    assert.are.same({ "one", "two" }, s.feed("one\ntwo\nthr"))
    assert.are.same("thr", s.flush())
  end)

  it("strips the CR of CRLF output", function()
    local s = line_stream.new()

    assert.are.same({ "one", "two" }, s.feed("one\r\ntwo\r\n"))
  end)

  it("strips the CR of a trailing partial too", function()
    local s = line_stream.new()

    s.feed("done\r")
    assert.are.same("done", s.flush())
  end)

  it("leaves a CR inside a line alone", function()
    local s = line_stream.new()

    assert.are.same({ "a\rb" }, s.feed("a\rb\n"))
  end)

  it("keeps a CRLF split across the chunk boundary intact", function()
    local s = line_stream.new()

    -- The worst case for anything that normalizes per chunk: the pair is
    -- torn in half, so neither chunk contains "\r\n" on its own.
    assert.are.same({}, s.feed("value\r"))
    assert.are.same({ "value" }, s.feed("\nnext"))
    assert.are.same("next", s.flush())
  end)

  it("keeps two streams from splicing into one another", function()
    local out = line_stream.new()
    local err = line_stream.new()

    assert.are.same({}, out.feed("foo"))
    assert.are.same({ "bar" }, err.feed("bar\n"))
    assert.are.same({ "foo" }, out.feed("\n"))
  end)
end)
