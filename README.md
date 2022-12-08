# MyWebHookFinal

## Purpose

Within this repository, I'd like to demonstrate the web hook triggered actions with GitHub API.

The assumed scenario is the security enforcement or the GitHub Organization.

There are various elements to enforce or increase the security, but the purpose of this particular project is to apply [Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches) to the default branch of the repository when the branch is newly created.

## General workflow

1. By the procedures described below, an [Organization webhook](https://docs.github.com/en/rest/orgs/webhooks?apiVersion=2022-11-28) is configured for the target Organization.
2. When the Organization event occurs, corresponding JSON message is sent to the web server, which is running on user's local PC.
3. The webhook handler on the web server checks the received JSON message. If it is not a relevant request, the handler discard it. The relevant request here is that with "created" action and with the existing default branch.
4. The handler would apply the branch protection rules to the notified repository's default branch. The rules are stored in local PC as JSON.
5. The handler would raise an issue to the repository. The issue tells that the branch protection is applied with the contact person and the applied branch protection rules.

## Preliminary

0. Latest MacOS is supposed to run the programs. The programs may work on Linux or other environment but not verified.
1. Install [cURL](https://curl.se), [Ruby](https://www.ruby-lang.org/en/), and [Sinatra](https://sinatrarb.com), if any of them are missing.
2. [Register and setup ngrok service](https://dashboard.ngrok.com/get-started/setup)
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

1. Sign in to GitHub, and go to the target Organization.
2. Create a *public* repository under the Organization. You have to create a README.md file at the repository creation time, otherwise the default branch is not instanciated simultaneously so the branch protection rules cannot be applied by the webhook.
3. Examine the branch protection rules of the newly created repository's default branch. Go "Settings" > "Branches".
4. Check the "Issues" of the repository.

## Limitation

1. The branch protection can be applied on *public* repository only.
2. The new repository should instanciate its default branch, by adding the initial README.md at repository creation time. Otherwise, the Orgnization webhook triggered by "created" action cannot add the branch protection because the default branch is not created at that point.
3. Communication between the webhook and the webhook-handler is not fully secured. The connection is secured by HTTPS, but the authentication with `X-Hub-Signature` is not implemented, so far.

## Appendix

You can also apply the branch protection rules to the existing repositories.

```
cd MyWebHookFinal
ruby applyToExistingRepos.rb
```

## Reference

I referred [GitHub Docs](https://docs.github.com/en) mainly.

To get the general ideas of protected branches quickly, [this article on Hatena Blog](https://kojirooooocks.hatenablog.com/entry/2018/05/11/033152) helped me.

Also I referred some random articles found by Google to get know-how of Ruby, Sinatra, and ngrok.
