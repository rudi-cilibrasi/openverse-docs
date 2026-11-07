-- openverse-docs — the web edition: the notation the PDF gets from tex/.
--
-- The PDF defines its notation in tex/common.tex (\kw, \evalj, \rulename, …)
-- and typesets inference rules with proof.sty's \infer. A web page has
-- neither, so for HTML this filter
--
--   * expands those macros, read from tex/common.tex itself so that there is
--     one definition, inside math, and rewrites
--     \infer[name]{conclusion}{premise & premise} as a fraction, which
--     pandoc's MathML writer understands (\rulename becomes \textsf there:
--     MathML has no small capitals);
--   * converts raw LaTeX in running text ("In \rulename{T-Ite} the …") by
--     expanding the macros and reading the result with pandoc's LaTeX reader,
--     instead of dropping it, which is what the HTML writer would do;
--   * letters the appendices: the headings after \appendix become
--     "Appendix A. …", unnumbered;
--   * makes links into the published site relative (see Link below).
--
-- Run it after filters/boxes.lua (scripts/build-site.sh does).

if FORMAT:match("latex") then return {} end

local function skip_ws(s, i)
  while i <= #s and s:sub(i, i):match("%s") do i = i + 1 end
  return i
end

-- s:sub(i, i) is `open`; returns what lies between it and its match, and the
-- index after the match. A backslash escapes the next character.
local function group(s, i, open, close)
  local depth, j = 0, i
  while j <= #s do
    local c = s:sub(j, j)
    if c == "\\" then
      j = j + 2
    else
      if c == open then
        depth = depth + 1
      elseif c == close then
        depth = depth - 1
        if depth == 0 then return s:sub(i + 1, j - 1), j + 1 end
      end
      j = j + 1
    end
  end
  error("web.lua: unbalanced " .. open .. " in: " .. s)
end

-- one macro argument: a {group}, a control sequence, or a character
local function argument(s, i)
  i = skip_ws(s, i)
  local c = s:sub(i, i)
  if c == "{" then return group(s, i, "{", "}") end
  if c == "\\" then
    local cs = s:match("^\\%a+", i) or s:sub(i, i + 1)
    return cs, i + #cs
  end
  return c, i + 1
end

-- \newcommand{\name}[n]{body}, one per line, from tex/common.tex
local function read_macros(path)
  local f = assert(io.open(path, "r"), "web.lua: cannot read " .. path)
  local macros = {}
  for line in f:lines() do
    local name, rest = line:match("^\\newcommand{\\(%a+)}(.*)$")
    if name then
      local n, i = 0, 1
      local count = rest:match("^%[(%d)%]")
      if count then n, i = tonumber(count), 4 end
      local body = group(rest, i, "{", "}")
      macros[name] = { n = n, body = body }
    end
  end
  f:close()
  return macros
end

local function with(base, overrides)
  local t = {}
  for k, v in pairs(base) do t[k] = v end
  for k, v in pairs(overrides) do t[k] = v end
  return t
end

local common = read_macros("tex/common.tex")
local math_macros = with(common, { rulename = { n = 1, body = "\\textsf{#1}" } })
local text_macros = with(common, { rulename = { n = 1, body = "\\textsc{#1}" } })

local function expand(s, macros)
  for _ = 1, 32 do
    local out, i, changed = {}, 1, false
    while i <= #s do
      local name = s:match("^\\(%a+)", i)
      if name and macros[name] then
        local m, j, args = macros[name], i + 1 + #name, {}
        for k = 1, m.n do args[k], j = argument(s, j) end
        table.insert(out, (m.body:gsub("#(%d)", function(d) return args[tonumber(d)] end)))
        i, changed = j, true
      elseif s:sub(i, i) == "\\" then
        local cs = s:match("^\\%a+", i) or s:sub(i, i + 1)
        table.insert(out, cs)
        i = i + #cs
      else
        table.insert(out, s:sub(i, i))
        i = i + 1
      end
    end
    s = table.concat(out)
    if not changed then return s end
  end
  error("web.lua: the macros do not terminate on: " .. s)
end

-- the premises of \infer are separated by & at brace depth 0
local function split_premises(p)
  local parts, depth, start, i = {}, 0, 1, 1
  while i <= #p do
    local c = p:sub(i, i)
    if c == "\\" then
      i = i + 1
    elseif c == "{" then
      depth = depth + 1
    elseif c == "}" then
      depth = depth - 1
    elseif c == "&" and depth == 0 then
      table.insert(parts, p:sub(start, i - 1))
      start = i + 1
    end
    i = i + 1
  end
  table.insert(parts, p:sub(start))
  return parts
end

local function rewrite_infer(s)
  while true do
    local i = s:find("\\infer%f[^%a]")
    if not i then return s end
    local j, label = skip_ws(s, i + #"\\infer"), ""
    if s:sub(j, j) == "[" then label, j = group(s, j, "[", "]") end
    local conclusion, premises
    conclusion, j = argument(s, j)
    premises, j = argument(s, j)
    local fraction = "\\dfrac{" .. table.concat(split_premises(premises), "\\qquad ") .. "}{" .. conclusion .. "}"
    if label ~= "" then fraction = "{" .. fraction .. "\\;" .. label .. "}" end
    s = s:sub(1, i - 1) .. fraction .. s:sub(j)
  end
end

-- a wide table scrolls sideways on a phone, inside a wrapper that takes
-- keyboard focus (book.css), like display math
function Table(el)
  return pandoc.Div({ el }, pandoc.Attr("", { "table-scroll" }, { tabindex = "0" }))
end

local function is_tex(el) return el.format == "tex" or el.format == "latex" end

-- The books link to the published site by its full address, which is right
-- in a PDF. In the web edition the same links are relative, so that a local or
-- pull-request build of the site links to itself and scripts/check-site.py
-- can check them.
local SITE = "https://rudi-cilibrasi.github.io/openverse-docs/"

function Link(el)
  if el.target:sub(1, #SITE) == SITE then
    el.target = "../" .. el.target:sub(#SITE + 1)
    return el
  end
  return nil
end

function Math(el)
  el.text = rewrite_infer(expand(el.text, math_macros))
  if el.mathtype == "DisplayMath" then
    -- a wide formula scrolls sideways on a phone; its wrapper takes keyboard
    -- focus so that the scrolling works without a mouse (book.css)
    return pandoc.Span({ el }, pandoc.Attr("", { "display-math" }, { tabindex = "0" }))
  end
  return el
end

function RawInline(el)
  if not is_tex(el) then return nil end
  local blocks = pandoc.read(expand(el.text, text_macros), "latex").blocks
  if #blocks == 0 then return {} end
  if #blocks > 1 or not blocks[1].content then
    error("web.lua: raw LaTeX in running text is not a phrase: " .. el.text)
  end
  return blocks[1].content
end

function RawBlock(el)
  if not is_tex(el) then return nil end
  if el.text:match("^%s*\\appendix%s*$") then return nil end -- see Pandoc below
  return pandoc.read(expand(el.text, text_macros), "latex").blocks
end

function Pandoc(doc)
  local blocks, appendix, letter = {}, false, 0
  for _, b in ipairs(doc.blocks) do
    if b.t == "RawBlock" and is_tex(b) and b.text:match("^%s*\\appendix%s*$") then
      appendix = true
    else
      if appendix and b.t == "Header" then
        b.classes:insert("unnumbered")
        if b.level == 1 then
          letter = letter + 1
          local prefix = { pandoc.Str("Appendix " .. string.char(64 + letter) .. "."), pandoc.Space() }
          b.content = pandoc.Inlines(prefix) .. b.content
        end
      end
      table.insert(blocks, b)
    end
  end
  doc.blocks = blocks
  return doc
end

-- Inline and block elements first, then the whole document.
return {
  { Math = Math, RawInline = RawInline, RawBlock = RawBlock, Link = Link, Table = Table },
  { Pandoc = Pandoc },
}
