--[[
 * Copyright (C) 2015 Bastien Nocera
 *
 * Contact: Bastien Nocera <hadess@hadess.net>
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

NASCAR_URL    = 'http://i.cdn.turner.com/nascar/feeds/partners/embeded_player/latest.xml'

---------------------------
-- Source initialization --
---------------------------

source = {
  id = "grl-nascar",
  name = "Nascar Videos",
  description = "Videos from nascar.com",
  supported_keys = { "id", "title", "description", "site", "thumbnail", "url" },
  supported_media = 'video',
  tags = { 'net:internet', 'net:plaintext' },
  icon = 'resource:///org/gnome/grilo/plugins/nascar/grilo/nascar.png'
}

-- Global table to store parse results
cached_xml = nil

------------------
-- Source utils --
------------------

function grl_source_browse()
  if cached_xml then
    parse_results(cached_xml)
  else
    local url = NASCAR_URL
    grl.debug('Fetching URL: ' .. url)
    grl.fetch(url, "nascar_fetch_cb")
  end
end

------------------------
-- Callback functions --
------------------------

function nascar_fetch_cb(results)
  if not results then
    grl.warning('Failed to fetch XML file')
    grl.callback()
    return
  end

  cached_xml = grl.lua.xml.string_to_table(results)
  print (grl.lua.inspect(cached_xml))
  parse_results(cached_xml)
end

function parse_results(results)
  local count = grl.get_options("count")
  local skip = grl.get_options("skip")
  local sent = false

  for i, item in pairs(results.NASCAR.ITEM) do
     if skip > 0 then
        skip = skip - 1
     elseif count > 0 then
        local media = {}
        count = count - 1 
        send_media(media, item, count)
        sent = true
     end
  end

  if not sent then
     grl.callback()
  end
end

function send_media(media, item, count)
  media.type = 'video'
  media.id = item.URL.ID
  media.title = item.TITLE.xml
  media.description = item.DESCRIPTION.xml
  media.site = item.URL.SITEURL.xml
  media.thumbnail = item.IMAGE.xml
  media.url = 'http://ht.cdn.turner.com/nascar/big/'..media.id..'.nascar_640x360.mp4'
  grl.callback(media, count)
end
