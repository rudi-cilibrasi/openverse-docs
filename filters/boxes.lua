-- openverse-docs — fenced divs as boxes, and the checked code-block classes.
--
--   ::: {.theorem title="Determinism"}      -> \begin{boxtheorem}{Determinism} … \end{boxtheorem}
--   (also .definition, .note, .exercise, .rule; the LaTeX environments are in tex/)
--   ```{.output}                             -> program output panel
--   ```{.verse .reject expect="…"}           -> the program, then a "rejected" panel
--
-- The classes .run, .check, .reject, .fragment, .claim and .excerpt matter to
-- scripts/check-books.py, not to the layout; they are removed here so that
-- the first class (verse, lean) selects the highlighter.
--
-- Other formats (the web edition, scripts/build-site.sh) get plain HTML with
-- classes that site/book.css styles:
--   <div class="box theorem"><div class="box-title">…</div> … </div>
--   <div class="output-panel"><pre>…</pre></div>    (class "empty" if no output)
--   <div class="reject-panel"><p><strong>Rejected:</strong> <code>…</code></p></div>

local boxes = { theorem = true, definition = true, note = true, exercise = true, rule = true }
local checkclasses = { run = true, check = true, reject = true, fragment = true, claim = true, excerpt = true }

local function latex_of_inline_markdown(s)
  if s == nil or s == "" then return "" end
  local doc = pandoc.read(s, "markdown")
  local inlines = {}
  if #doc.blocks > 0 and doc.blocks[1].content then inlines = doc.blocks[1].content end
  return pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "latex"):gsub("%s+$", "")
end

local function inlines_of_markdown(s)
  if s == nil or s == "" then return {} end
  local doc = pandoc.read(s, "markdown")
  if #doc.blocks > 0 and doc.blocks[1].content then return doc.blocks[1].content end
  return {}
end

local function escape_latex(s)
  return (s:gsub("\\", "\\textbackslash{}"):gsub("([{}#%%&_%$])", "\\%1")
           :gsub("%^", "\\textasciicircum{}"):gsub("~", "\\textasciitilde{}"))
end

local function box_html(el, c)
  local out = {}
  local title = inlines_of_markdown(el.attributes["title"])
  if #title > 0 then
    table.insert(out, pandoc.Div({ pandoc.Plain(title) }, pandoc.Attr("", { "box-title" })))
  end
  for _, b in ipairs(el.content) do table.insert(out, b) end
  return pandoc.Div(out, pandoc.Attr(el.identifier, { "box", c }))
end

function Div(el)
  for _, c in ipairs(el.classes) do
    if boxes[c] then
      if not FORMAT:match("latex") then return box_html(el, c) end
      local title = latex_of_inline_markdown(el.attributes["title"] or "")
      local out = { pandoc.RawBlock("latex", "\\begin{box" .. c .. "}{" .. title .. "}") }
      for _, b in ipairs(el.content) do table.insert(out, b) end
      table.insert(out, pandoc.RawBlock("latex", "\\end{box" .. c .. "}"))
      return out
    end
  end
  return nil
end

function CodeBlock(el)
  local is = {}
  for _, c in ipairs(el.classes) do is[c] = true end
  local kept = {}
  for _, c in ipairs(el.classes) do if not checkclasses[c] then table.insert(kept, c) end end

  if is["output"] then
    if not FORMAT:match("latex") then
      if el.text:match("^%s*$") then
        return pandoc.Div({ pandoc.Para({ pandoc.Emph({ pandoc.Str("(no output)") }) }) },
          pandoc.Attr("", { "output-panel", "empty" }))
      end
      return pandoc.Div({ pandoc.CodeBlock(el.text) }, pandoc.Attr("", { "output-panel" }))
    end
    if el.text:match("^%s*$") then
      return pandoc.RawBlock("latex", "\\begin{outputpanel}\\textit{\\rmfamily (no output)}\\end{outputpanel}")
    end
    return {
      pandoc.RawBlock("latex", "\\begin{outputpanel}"),
      pandoc.CodeBlock(el.text),
      pandoc.RawBlock("latex", "\\end{outputpanel}"),
    }
  end

  local block = pandoc.CodeBlock(el.text, pandoc.Attr(el.identifier, kept, {}))
  if is["reject"] and not FORMAT:match("latex") then
    return {
      block,
      pandoc.Div({ pandoc.Para({ pandoc.Strong({ pandoc.Str("Rejected:") }), pandoc.Space(),
        pandoc.Code(el.attributes["expect"] or "") }) }, pandoc.Attr("", { "reject-panel" })),
    }
  end
  if is["reject"] then
    local expect = el.attributes["expect"] or ""
    return {
      block,
      pandoc.RawBlock("latex", "\\begin{rejectpanel}\\textsf{\\textbf{Rejected:}} \\texttt{"
        .. escape_latex(expect) .. "}\\end{rejectpanel}"),
    }
  end
  return block
end
