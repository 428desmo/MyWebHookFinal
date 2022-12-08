require 'json'

# Create a personal access token (classic)
# and store it in ~/personal_access_token.txt
#
# Reference:
#   https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token

token = `cat ~/personal_access_token.txt`.chomp
organization = `cat ~/organization_name.txt`.chomp


webhook_handler_port = 4567
ngrok_localhost_status_port = 4040


curl_output = `curl -s http://localhost:#{webhook_handler_port}/`
if curl_output.nil? || curl_output.empty? then
    puts "start the webhook handler server (in another terminal)"
    puts "% ruby WebHookReceiver.rb -p 4567 -o 0.0.0.0"
    exit
end

curl_output = `curl -s http://localhost:#{ngrok_localhost_status_port}/api/tunnels`
if curl_output.nil? || curl_output.empty? then
    puts "start the ngrok (in another terminal)"
    puts "% ngrok http #{webhook_handler_port}"
    exit
end

params = JSON.parse(curl_output)

if params.nil? then
    puts "error: ngrok seems not working correctly. kill and retry"
    puts "% pkill ngrok"
    exit
else
    public_url = params.dig("tunnels", 0, "public_url")

    if public_url && !public_url.empty? then
        command = <<~EOS
            curl -s \
            -X POST \
            -H \"Accept: application/vnd.github+json\" \
            -H \"Authorization: Bearer #{token}\" \
            -H \"X-GitHub-Api-Version: 2022-11-28\" \
            https://api.github.com/orgs/#{organization}/hooks \
            -d '{\"name\":\"web\", \
                 \"active\":true, \
                 \"events\":[\"repository\"], \
                 \"config\":{\"url\":\"#{public_url}/payload\", \
                             \"content_type\":\"json\"}}'
        EOS

        `#{command}`
    end
end
