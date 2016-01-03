--[[
 * Copyright (C) 2016 Grilo Project
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA
 *
--]]

CCO_URL = 'http://www.classiccinemaonline.com'

---------------------------
-- Source initialization --
---------------------------

source = {
  id = "grl-classic-cinema-online",
  name = "Classic Cinema Online",
  description = "Watch online video movies found at http://www.classiccinemaonline.com.  The site aggregates old movies and tv shows found on google video and archive.org",
  supported_keys = { 'id' },
  supported_media = 'video',
  tags = { 'tv', 'net:internet', 'net:plaintext' }
}

---------------------------------
-- Handlers of Grilo functions --
---------------------------------

function grl_source_browse(media_id)
   if not media_id then
      grl.fetch(CCO_URL, "fetch_cb")
      return
   end
   grl.callback()
end

---------------
-- Utilities --
---------------

function fetch_cb(results)
   local ul = results:match('<ul class="gf-menu l1 ">')
   local xml = grl.lua.xml.string_to_table(results)
   print(grl.lua.inspect(xml))
   grl.callback()
end
