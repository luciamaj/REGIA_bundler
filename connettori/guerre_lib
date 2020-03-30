#!/usr/bin/env ruby

require 'json'
require 'open-uri'

data = {
    "name" => "guerre_lib",
    "layout" => "guerre",
}


open('http://localhost:8080/swi/service/rest/v1/app-totem') { |content| data["data"] = JSON.parse(content.read) }

puts JSON.generate(data)
