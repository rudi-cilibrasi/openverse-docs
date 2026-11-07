-- promodoc — fenced divs as boxes, and the checked code-block classes.
--
--   ::: {.theorem title="Determinism"}      -> \begin{boxtheorem}{Determinism} … \end{boxtheorem}
--   (also .definition, .note, .exercise, .rule; the LaTeX environments are in tex/)
--   ```{.output}                             -> program output panel
--   ```{.verse .reject expect="…"}           -> the program, then a "rejected" panel
--
-- The classes .run, .check, .reject, .fragment, .claim and .excerpt matter to
-- scripts/check-books.py, not to the layout; they are removed here so that
-- the first class (verse, lean) selects the highlighter.

local boxes = { theorem = true, definition = true, note = true, exercise = true, rule = true }
local checkclasses = { run = true, check = true, reject = true, fragment = true, claim = true, excerpt = true }

local function latex_of_inline_markdown(s)
  if s == nil or s == "" then return "" end
  local doc = pandoc.read(s, "markdown")
  local inlines = {}
  if #doc.blocks > 0 and doc.blocks[1].content then inlines = doc.blocks[1].content end
  return pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "latex"):gsub("%s+$", "")
end

local function escape_latex(s)
  return (s:gsub("\\", "\\textbackslash{}"):gsub("([{}#%%&_%$])", "\\%1")
           :gsub("%^", "\\textasciicircum{}"):gsub("~", "\\textasciitilde{}"))
end

function Div(el)
  if not FORMAT:match("latex") then return nil end
  for _, c in ipairs(el.classes) do
    if boxes[c] then
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
    if not FORMAT:match("latex") then return nil end
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
  if is["reject"] and FORMAT:match("latex") then
    local expect = el.attributes["expect"] or ""
    return {
      block,
      pandoc.RawBlock("latex", "\\begin{rejectpanel}\\textsf{\\textbf{Rejected:}} \\texttt{"
        .. escape_latex(expect) .. "}\\end{rejectpanel}"),
    }
  end
  return block
end
