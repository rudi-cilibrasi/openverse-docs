-- promodoc — the question-and-answer layout of The Little Verser.
--
-- Inside a ::: qa div, every block quote is an answer, and the blocks before
-- it (since the previous answer) are its question:
--
--   ::: qa
--   What is `1 + 2`?
--
--   > `3`.
--   :::
--
-- In LaTeX each pair becomes two top-aligned minipages, question on the left
-- and answer on the right (tex/little-verser.tex). Other formats get a
-- <div class="qa-pair"> with a "q" and an "a" div.

local function pair_latex(q, a)
  local out = { pandoc.RawBlock("latex", "\\qabegin") }
  for _, b in ipairs(q) do table.insert(out, b) end
  table.insert(out, pandoc.RawBlock("latex", "\\qamid"))
  for _, b in ipairs(a) do table.insert(out, b) end
  table.insert(out, pandoc.RawBlock("latex", "\\qaend"))
  return out
end

local function pair_generic(q, a)
  return { pandoc.Div({ pandoc.Div(q, pandoc.Attr("", { "q" })), pandoc.Div(a, pandoc.Attr("", { "a" })) },
    pandoc.Attr("", { "qa-pair" })) }
end

function Div(el)
  if not el.classes:includes("qa") then return nil end
  local out, q = {}, {}
  local make = FORMAT:match("latex") and pair_latex or pair_generic
  for _, b in ipairs(el.content) do
    if b.t == "BlockQuote" then
      if #q == 0 then
        error("qa.lua: an answer without a question: " .. pandoc.utils.stringify(b):sub(1, 60))
      end
      for _, x in ipairs(make(q, b.content)) do table.insert(out, x) end
      q = {}
    else
      table.insert(q, b)
    end
  end
  if #q > 0 then
    error("qa.lua: a question without an answer: " .. pandoc.utils.stringify(q[1]):sub(1, 60))
  end
  return out
end
