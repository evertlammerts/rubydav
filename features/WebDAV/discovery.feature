Feature: Service discovery
  In order to mount and browse the WebDAV namespace
  Clients must be able to discover WebDAV functionality

Background:
  Given user "cucumber" exists

Scenario: OPTIONS request on *
  When I perform an HTTP/1.1 OPTIONS request on "*"
  Then I should see the following response headers:
    | DAV           | 1                                    |
    | DAV           | 3                                    |
    | DAV           | <http://apache.org/dav/propset/fs/1> |
    | MS-Author-Via | DAV                                  |
    | Allow         | OPTIONS                              |

Scenario: OPTIONS request on an existing collection
  Given collection "<collection>" exists
  When I perform an HTTP/1.1 OPTIONS request on "<collection>"
  Then I should see the following response headers:
    | DAV           | 1                                    |
    | DAV           | 3                                    |
    | DAV           | <http://apache.org/dav/propset/fs/1> |
    | MS-Author-Via | DAV                                  |
    | Allow         | COPY                                 |
    | Allow         | DELETE                               |
    | Allow         | GET                                  |
    | Allow         | HEAD                                 |
    | Allow         | MOVE                                 |
    | Allow         | OPTIONS                              |
    | Allow         | PROPFIND                             |
    | Allow         | PROPPATCH                            |
    | Allow         | REPORT                               |

Scenario: OPTIONS request on a non-existing collection
  Given collection "<collection>" doesn't exist
  When I perform an HTTP/1.1 OPTIONS request on "<collection>"
  Then I should see the following response headers:
    | DAV           | 1                                    |
    | DAV           | 3                                    |
    | DAV           | <http://apache.org/dav/propset/fs/1> |
    | MS-Author-Via | DAV                                  |
    | Allow         | MKCOL                                |
    | Allow         | OPTIONS                              |

Scenario Outline: OPTIONS request on an existing file
  Given file "<file>" exists
  When I perform an HTTP/1.1 OPTIONS request on "<file>"
  Then I should see the following response headers:
    | DAV           | 1                                    |
    | DAV           | 3                                    |
    | DAV           | <http://apache.org/dav/propset/fs/1> |
    | MS-Author-Via | DAV                                  |
    | Allow         | COPY                                 |
    | Allow         | DELETE                               |
    | Allow         | GET                                  |
    | Allow         | HEAD                                 |
    | Allow         | MOVE                                 |
    | Allow         | OPTIONS                              |
    | Allow         | PROPFIND                             |
    | Allow         | PROPPATCH                            |
    | Allow         | PUT                                  |
    | Allow         | REPORT                               |
  Examples:
    | file                        |
    | /~pieterb/                  |
    | /~pieterb/cucumber/test.txt |

Scenario Outline: OPTIONS request on a non-existing file
  Given file "<file>" doesn't exist
  When I perform an HTTP/1.1 OPTIONS request on "<file>"
  Then I should see the following response headers:
    | DAV           | 1                                    |
    | DAV           | 3                                    |
    | DAV           | <http://apache.org/dav/propset/fs/1> |
    | MS-Author-Via | DAV                                  |
    | Allow         | PUT                                  |
    | Allow         | OPTIONS                              |
  Examples:
    | file          |
    | /non-existing |

