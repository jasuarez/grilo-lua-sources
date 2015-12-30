--[[
 * Copyright (C) 2015 Igalia, S.L.
 *
 * Contact: Juan A. Suarez Romero <jasuarez@igalia.com>
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

RADIO_BASE = 'https://rad.io/info'
RADIO_SEARCH_URL = RADIO_BASE .. '/index/searchembeddedbroadcast?q=%s&start=%d&rows=%d&streamcontentformats=mp3'
RADIO_BROADCAST_DETAILS_URL = RADIO_BASE .. '/broadcast/getbroadcastembedded?broadcast=%s'
RADIO_CATEGORIES_URL = RADIO_BASE .. '/menu/valuesofcategory?category=_%s'
RADIO_STATIONS_BY_CATEGORY_URL = RADIO_BASE .. '/menu/broadcastsofcategory?category=_%s&value=%s'

---------------------------
-- Source initialization --
---------------------------

source = {
  id = "grl-online-radio",
  name = "On-Line Radio",
  description = "Radios from rad.io",
  supported_keys = { "id", "title", "thumbnail", "genre" },
  supported_media = 'audio',
  tags = { 'music', 'net:internet' },
  icon = 'resource:///org/gnome/grilo/plugins/online-radio/grilo/online-radio.png'
}

netopts = {
   user_agent = "radio.de 1.9.1 rv:37 (iPhone; iPhone OS 5.0; de_DE)"
}

categories = {
   ["genre"] = "Genres",
   ["topic"] = "Topics",
   ["country"] = "Countries",
   ["city"] = "City",
   ["language"] = "Language",
}

------------------
-- Source utils --
------------------

function grl_source_browse(media_id)
   if not media_id then
      for k, v in pairs(categories) do
         local media = {}
         media.type = 'box'
         media.id = k
         media.title = v
         grl.callback(media, -1)
      end
      grl.callback()
      return
   end

   local id_token = split(media_id, '/')
   if id_token[2] then
      local url = string.format(RADIO_STATIONS_BY_CATEGORY_URL, id_token[1], id_token[2])
      grl.fetch(url, "search_cb", netopts)
   else
      local url = string.format(RADIO_CATEGORIES_URL, media_id)
      grl.fetch(url, "categories_cb", netopts)
   end
end

function grl_source_search(term)
  local skip = grl.get_options("skip")
  local count = grl.get_options("count")

  local url = string.format(RADIO_SEARCH_URL, term, skip, count)
  grl.fetch(url, "search_cb", netopts)
end

------------------------
-- Callback functions --
------------------------

function categories_cb(results)
   local json = grl.lua.json.string_to_table(results)
   for i, category in ipairs(json) do
      local media = {}
      media.type = 'box'
      media.title = category
      -- FIXME: Use proper category
      media.id = 'genre/' .. category
      grl.callback(media, #json - i)
   end
end

function search_cb(results)
   local count = grl.get_options("count")
   local json = grl.lua.json.string_to_table(results)
   print(grl.lua.inspect(json))

   for i, radio in pairs(json) do
      count = count - 1;
      local r = parse_radio(radio)
      --get_broadcast(r.id, r)
      grl.callback(r, count)
   end
end

function broadcast_cb(results)
   local json = grl.lua.json.string_to_table(results)
   print(grl.lua.inspect(json))
end

function get_broadcast(id, radio)
   print("######################")
   local url = string.format(RADIO_BROADCAST_DETAILS_URL, id)
   grl.fetch(url, "broadcast_cb", netopts)
end

function parse_radio(radio, count)
   local media = {}

   media.type = 'audio'
   media.id = split(radio.id, "%.")[1]
   media.title = radio.name
   media.thumbnail = radio.pictureBaseURL .. radio.picture1Name
   media.genre = split(radio.genresAndTopics, ",")
   return media
end

function split(str, l)
   local t = {}
   for k in string.gmatch(str, "[^" .. l .. "]+") do
      table.insert(t, trim(k))
   end
   return t
end

function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end
