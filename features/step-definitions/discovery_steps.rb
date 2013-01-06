When %r{^I perform an HTTP/1\.1 OPTIONS request on "(\S+)"$} do |path|
  @response = @http.start do |session|
    request = Net::HTTP::Options.new(path).authenticated
    response = session.request( request )
  end
end

Then %r{^I should see the following response headers:$} do |table|
  headers = @response.to_hash
  headers = Hash[
    headers.collect do |name, value|
      value = value.join ','
      [ name, value.split(/,\s*/) ]
    end
  ]
  raise 'Missing required header' unless table.raw.all? do |name, value|
    name = name.downcase
    headers[name] && headers[name].include?( value )
  end
end
