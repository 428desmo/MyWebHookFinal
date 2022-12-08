require 'json'

# Create a personal access token (classic)
# and store it in ~/personal_access_token.txt
#
# Reference:
#   https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token


token = `cat ~/personal_access_token.txt`.chomp
organization = `cat ~/organization_name.txt`.chomp

listCmd = "curl -s " \
          " -H \"Accept: application/vnd.github+json\"" \
          " -H \"Authorization: Bearer #{token}\""\
          " -H \"X-GitHub-Api-Version: 2022-11-28\"" \
          " https://api.github.com/orgs/#{organization}/hooks"

json = `#{listCmd}`


found = 0
deleted = 0

if json && !json.empty? then
  params = JSON.parse(json)
  params.each{
    |key|
    url = key.dig("url")
    type = key.dig("type")
    if type != "Organization" then
      next
    end

    found += 1

    puts "An organization wekbook is found:"
    puts key.to_json
    while true
      print "Delete or Keep (deafault)? [d|k]:"
      input = gets
      case input
      when /^[dD]/
        puts "DELETE: Deleting the web hook"
        if url then
          deleteCmd = "curl -s " \
                      " -X DELETE" \
                      " -H \"Accept: application/vnd.github+json\"" \
                      " -H \"Authorization: Bearer #{token}\""\
                      " -H \"X-GitHub-Api-Version: 2022-11-28\"" \
                      " #{url}"
          `#{deleteCmd}`
          deleted += 1
        end
        break
      when /^[kK]/, /^$/
        puts "KEEP: Keeping the web hook"
        break
      end
    end
    puts
  }
  puts "Found #{found} Organization webhooks on #{organization}"
  puts "Deleted #{deleted} Organization webhooks on #{organization}"
end
