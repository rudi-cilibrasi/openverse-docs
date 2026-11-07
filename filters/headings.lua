-- openverse-docs — the sections of an unnumbered chapter are unnumbered.
--
-- "# Preface {.unnumbered}" is a chapter without a number, but pandoc would
-- still number its sections 0.1, 0.2, … in the PDF and on the web. Here every
-- heading below an unnumbered chapter heading becomes unnumbered too (it stays
-- in the table of contents). Used by scripts/build.sh and scripts/build-site.sh.

function Pandoc(doc)
  local unnumbered = false
  for _, b in ipairs(doc.blocks) do
    if b.t == "Header" then
      if b.level == 1 then
        unnumbered = b.classes:includes("unnumbered")
      elseif unnumbered and not b.classes:includes("unnumbered") then
        b.classes:insert("unnumbered")
      end
    end
  end
  return doc
end
