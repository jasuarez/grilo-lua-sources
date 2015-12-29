--[[
 * Copyright (C) 2015 Grilo Project
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

DILBERT = 'http://dilbert.com'
DILBERT_BROWSE = DILBERT .. '/strips/comic/'
DILBERT_SEARCH = 'http://search.dilbert.com/search?w=%s&srt=%d'

MIN_DATE = { 1989, 3, 16 }

MAX_DATE = { tonumber(os.date('%Y')),
             tonumber(os.date('%m')),
             tonumber(os.date('%d')) }

MONTHS = { 'January', 'February', 'March', 'April',
           'May', 'June', 'July', 'August',
           'September', 'October', 'November', 'December' }

---------------------------
-- Source initialization --
---------------------------

source = {
  id = "grl-dilbert",
  name = "Dilbert",
  description = "Display daily Dilbert comic strip",
  supported_keys = { 'creation-date', 'title', 'id', 'url' },
  slow_keys = { 'url' },
  supported_media = 'image',
  tags = { 'comic', 'net:internet', 'net:plaintext' },
  auto_split_threshold = 6
}

---------------------------------
-- Handlers of Grilo functions --
---------------------------------
function grl_source_browse(media_id)
   print("Running browse")
   local year, month = split_id(media_id)
   if not year then
      send_years()
   elseif not month then
      send_months(year)
   else
      send_days(year, month)
   end
end

function grl_source_resolve()
   print("Running resolve")
   if url_requested() then
      local keys = grl.get_media_keys()
      if not keys then
         grl.callback()
         return
      end

      local year, month, day = split_id(keys.id)
      if not day then
         grl.callback()
         return
      end

      local url = { DILBERT_BROWSE .. year .. '-' .. month .. '-' .. day }
      grl.fetch(url, "fetch_browse_results_cb")
   else
      grl.callback()
   end
end

function grl_source_search(text)
   if not text or text == "" then
      send_all()
      return
   end

   local url = string.format(DILBERT_SEARCH, text, grl.get_options('skip'))
   grl.fetch(url, "fetch_search_results_cb")
end

---------------
-- Utilities --
---------------
function send_years()
   local skip = grl.get_options('skip')
   local count = grl.get_options('count')
   local last_year = math.max(MAX_DATE[1] - skip, MIN_DATE[1])
   local first_year = math.max(last_year - count + 1, MIN_DATE[1])

   if first_year > last_year then
      grl.callback()
      return
   end

   for year=last_year,first_year,-1 do
      local media = {}
      media.id = year
      media.type = 'box'
      media.title = year
      grl.callback(media, year - first_year)
   end
end

function send_months(year)
   local first_month, last_month

   local skip = grl.get_options('skip')
   local count = grl.get_options('count')

   if year == MAX_DATE[1] then
      last_month = math.max(MAX_DATE[2] - skip, 1)
      first_month = math.max(last_month - count + 1, 1)
   elseif year == MIN_DATE[1] then
      last_month = math.max(12 - skip, 1)
      first_month = math.max(last_month - count + 1, MIN_DATE[2])
   else
      last_month = math.max(12 - skip, 1)
      first_month = math.max(last_month - count + 1, 1)
   end

   if first_month > last_month then
      grl.callback()
      return
   end

   for month=last_month,first_month,-1 do
      local media = {}
      media.id = year .. '-' .. month
      media.type = 'box'
      media.title = MONTHS[month]
      grl.callback(media, month - first_month)
   end
end

function send_days(year, month)
   local first_day, last_day

   local skip = grl.get_options('skip')
   local count = grl.get_options('count')
   local requested_keys = grl.get_requested_keys()
   local max_day_in_month = os.date('*t', os.time{year=year,month=month+1,day=0})['day']

   if year == MAX_DATE[1] and month == MAX_DATE[2] then
      last_day = math.max(MAX_DATE[3] - skip, 1)
      first_day = math.max(last_day - count + 1, 1)
   elseif year == MIN_DATE[1] and month == MIN_DATE[2] then
      last_day = math.max(max_day_in_month - skip, 1)
      first_day = math.max(last_day - count + 1, MIN_DATE[3])
   else
      last_day = math.max(max_day_in_month - skip, 1)
      first_day = math.max(last_day - count + 1, 1)
   end

   if first_day > last_day then
      grl.callback()
      return
   end

   if url_requested() then
      local urls = {}
      for day=last_day,first_day,-1 do
         table.insert(urls, DILBERT_BROWSE .. year .. '-' .. month .. '-' .. day)
      end
      grl.fetch(urls, "fetch_browse_results_cb")
   else
      for day=last_day,first_day,-1 do
         grl.callback(build_image(year, month, day), day - first_day)
      end
   end
end

function send_all()
   local skip = grl.get_options('skip')
   print(skip)
   local year = MAX_DATE[1]
   local days_in_year = tonumber(os.date('%j', os.time{year=year,month=12,day=31}))
   while skip >= days_in_year and year >= MIN_DATE[1] do
      skip = skip - days_in_year
      year = year - 1
      days_in_year = os.date('%j', os.time{year=year,month=12,day=21})
   end

   local month = 12
   if year == MAX_DATE[1] then
      month = MAX_DATE[2]
   end
   local days_in_month = os.date('*t', os.time{year=year,month=month+1,day=0})['day']
   while skip >= days_in_month and ((year == MIN_DATE[1] and month >= MIN_DATE[2]) or month > 0) do
      skip = skip - days_in_month
      month = month - 1
      days_in_month = os.date('*t', os.time{year=year,month=month+1,day=0})['day']
   end

   local day
   if year == MAX_DATE[1] and month == MAX_DATE[2] then
      day = MAX_DATE[3] - skip
   else
      day = days_in_month - skip
   end

   if day < 1 or (year == MIN_DATE[1] and month == MIN_DATE[2] and day < MIN_DATE[3]) then
      grl.callback()
      return
   end

   local url_req
   local urls = {}
   if url_requested() then
      url_req = true
   else
      url_req = false
   end

   local count = grl.get_options('count')
   while year >= MIN_DATE[1] and count > 0 do
      local min_month = 1
      if year == MIN_DATE[1] then
         min_month = MIN_DATE[2]
      end
      while (month >= min_month) and (count > 0) do
         local min_day = 1
         if min_month ~= 0 then
            min_day = MIN_DATE[2]
         end
         while (day >= min_day) and (count > 0) do
            if url_req then
               table.insert(urls, DILBERT_BROWSE .. year .. '-' .. month .. '-' .. day)
            else
               grl.callback(build_image(year, month, day), -1)
            end
            count = count -1
            day = day - 1
         end
         month = month - 1
         day = os.date('*t', os.time{year=year,month=month+1,day=0})['day']
      end
      year = year - 1
      month = 12
      day = 31
   end

   if url_req then
      grl.fetch(urls, "fetch_browse_results_cb")
   else
      grl.callback()
   end
end

function fetch_search_results_cb(results)
   local count = grl.get_options('count')
   local id_match = 'title="' .. DILBERT_BROWSE .. '(.-)/"'
   local url_match = 'title="(' .. DILBERT .. '/dyn/str_strip/.-strip.zoom.gif)"'
   for section in results:gmatch('<a class="sli_link"(.-)<div class="sli_image"') do
      local id = section:match(id_match)
      local url = section:match(url_match)
      local year, month, day = split_id(id)
      local media = build_image(year, month, day)
      media.url = url
      count = count - 1
      grl.callback(media, count)
      if count == 0 then
         break
      end
   end
end

function fetch_browse_results_cb(results)
   if not results then
      grl.callback()
      return
   end

   local num_results = #results

   for i, result in ipairs(results) do
      media = parse_result(result)
      grl.callback(media, num_results - i)
   end
end

function parse_result(result)
   local id = result:match('"strip_enlarged_(.-)"')
   local url = result:match('<img src="(/dyn/str_strip/.-strip.zoom.gif)"')
   local year, month, day = split_id(id)
   media = build_image(year, month, day)
   media.url = DILBERT .. url

   return media
end

function split_id(id)
   if not id then
      return nil, nil, nil
   end

   local split_date = {}
   id:gsub('([^-]+)', function(s) table.insert(split_date, tonumber(s)) end)

   return split_date[1], split_date[2], split_date[3]
end

function url_requested()
   local requested_keys = grl.get_requested_keys()
   for _v, v in ipairs(requested_keys) do
      if v == 'url' then
         return true
      end
   end

   return false
end

function build_image(year, month, day)
   local media = {}
   media.type = 'image'
   media.id = year .. '-' .. month .. '-' .. day
   media.creation_date = media.id
   media.title = 'The Dilbert Strip for ' .. MONTHS[month] .. ' ' .. day .. ', ' .. year

   return media
end
