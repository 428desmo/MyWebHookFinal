# MyWebHookFinal
To demonstrate the web hook triggered actions with GitHub API

## General workflow


TBD



## Preliminary

0. Latest MacOS is supposed to run the programs. The programs may work on Linux or other environment but not verified.

1. Install [cURL](https://curl.se), [Ruby](https://www.ruby-lang.org/en/), and [Sinatra](https://sinatrarb.com), if any of them are missing.

2. (Register and setup ngrok service)[https://dashboard.ngrok.com/get-started/setup]

3. [Create a personal access token (classic)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) and store it in `~/personal_access_token.txt`

4. Put the name of your Organization, which this webhook-triggerd app would apply to, into a file.
`echo "<YOUR ORGANIZATION>" > ~/organization_name.txt`

5. Similarly put your user name (e.g. `@428desmo`) into a file
`echo "<YOUR USERNAME>" > ~/github_user_name.txt`

6. Edit `MyWebHookFinal/branch-protection-rule.json` to reflect the branch protection rules that you wish to apply.


## Run the programs on local PC

Open 3 terminals.

In terminal 1:
```
cd MyWebHookFinal
ruby WebHookReceiver.rb -p 4567 -o 0.0.0.0
```

In terminal 2:
```
cd MyWebHookFinal
ngrok http 4040
```

In terminal 3:
```
cd MyWebHookFinal

# If you need to check existing Organization webhooks
# You can delete existing ones if you wish
ruby checkWebHooks.rb

# Set up a new Organization webhook
ruby setupWebHook.rb
```

## Try the webhook

1. Sign in to GitHub

2. Create a *public* repository under the Organization. You should create a README.md file at the repository creation time, otherwise the default branch is not instanciated at this time so the branch protection rules cannot be applied by the webhook.

3. Examine the branch protection rules of the newly created repository's default branch. Go "Settings" > "Branches".

4. Check the "Issues" of the repository.

## Appendix

You can also apply the branch protection rules to the existing repositories.

```
cd MyWebHookFinal
ruby applyToExistingRepos.rb
```


