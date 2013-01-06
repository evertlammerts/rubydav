Feature: Responding to the WebDAV PROPFIND method.

Background:
  Given user "cucumber" exists
  And user "cucumber" has a sponsor

Scenario Outline:
  When I perform a PROPFIND request on "/" with Depth: <depth> and body <body>
  Then I should recieve a valid multistatus response
  And the multistatus response should contain, for each resource:
    | DAV: displayname |
    | DAV: getcontentlength |
    | DAV: getcontenttype |
    # TODO: others
  And the response should contain entries with the proper depth
  Examples:
    | depth | body       |
    | 1     | <allprop/> |
    | 1     |            |
    | 0     | <allprop/> |
    | 0     |            |

# TODO: <propnames/>