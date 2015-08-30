-- convert string to boolean
function strToBool(str)
   if str == "true" then
      return true
   elseif str == "false" then
      return false
   else
      return nil
   end
end

---
-- Splits a string on the given pattern, returned as a table of the delimited strings.
-- @param str the string to parse through
-- @param pat the pattern/delimiter to look for in str
-- @return a table of the delimited strings. If pat is empty, returns str. If str is not given, aka '' is given, then it returns an empty table.
function split(str, pat)
   if pat == '' then
      return str
   end

   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

-- Get just the filename, none of the folder parts.
function justFilename(filePath)
   if filePath ~= "" then
      local filenameParts = split(filePath, '/')
      return filenameParts[#filenameParts]
   else
      return ""
   end
end

--convert filename to Windows compliant
function fileToWindowsFile(str)
   local partsList = split(str, '/')
   local ret = ""
   
   for i, part in pairs(partsList) do
      if i == 1 then
         ret = part
      else
         ret = ret .. "\\" .. part
      end
   end
   
   return ret
end