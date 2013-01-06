Given %r{^user "(.*?)" exists$} do |user|
  pending # express the regexp above with the code you wish you had
end

Given %r{^user "(.*?)" has a sponsor$} do |user|
  pending # express the regexp above with the code you wish you had
end

Given %r{^(?:file|collection) "(.*?)" (?:exists|doesn't exist)$} do |path, exists|
  exists = 'exists' == exists
  pending
end

