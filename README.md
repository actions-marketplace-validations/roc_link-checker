# Broken link checker action 🕵️‍♂️

Find broken links in your website.

This action uses the node based [broken-link-checker](https://github.com/stevenvachon/broken-link-checker) and is heavily based on [the lychee link checker action](https://github.com/lycheeverse/lychee-action) and [celinekurpershoek's link checker action](https://github.com/celinekurpershoek/link-checker).

## How to use

Create a new file in your repository .github/workflows/find-broken-links.yml.

### Add link checking on push

You can pass in any of the options availible in the [broken link checker cli](https://github.com/stevenvachon/broken-link-checker/blob/main/lib/cli.js#L549-L570)

```yml
name: Broken link check
on: [push]

jobs:
  broken_link_checker_job:
    runs-on: ubuntu-latest
    name: Check for broken links
    steps:
      - name: Check for broken links
        id: link-report
        uses: roc/link-checker@master
        with:
          url: {WEBSITE_LOCATION}
          blc_args: --verbose --exclude github --follow false # can be any blc args
          allow_failures: true # do not fail the job if broken links are found
      - name: Get the result
        run: |
          echo "steps.link-report.outputs.exit_code was:" ${{steps.link-report.outputs.exit_code}}
          echo "cat ${{steps.link-report.outputs.report}}"
          cat ${{steps.link-report.outputs.report}}
```

### Create a ticket when a broken link is detected

You may not want to fail a job when broken links are detected. This can be achieved by passing `allow_failures: true` and adding an additional action step:

```yml
name: Broken link check with issue creation
on: [push]

jobs:
  brokenLinks:
    runs-on: ubuntu-latest
    name: Check links, Create issue
    steps:
      - name: Check for broken links
        id: link-report
        uses: roc/link-checker@master
        with:
          url: "https://github.com/roc/link-checker"
          # important: https://fooasldn.com/ comes back as BLC_ROBOTS without follow=true
          blc_args: --verbose --exclude github --follow true
          allow_failures: true
          output_file: yeah/blc/out.md

      - name: Create Issue From File
        uses: peter-evans/create-issue-from-file@v4
        # See https://docs.github.com/en/actions/using-jobs/using-conditions-to-control-job-execution
        if: ${{ steps.link-report.outputs.exit_code != 0 }}
        with:
          title: Link Checker Report for github.com/roc/link-checker
          content-filepath: ${{steps.link-report.outputs.report}}
          labels: report, automated issue
```

## workflow inputs

This workflow takes blc options as `blc_args` but has some additional inputs:

```
  url:
    description: "Url of site"
    required: true
    default: "https://github.com/roc/link-checker"
```

```
  allow_failures:
    description: "Pass the job even if the link checker finds broken links"
    required: false
    default: false
  output_file:
    description: "Summary output file path"
    default: "blc/out.md"
    required: false
```

The output file generated is attached to the workflow report and can be passed to a subsequent step to raise an issue.

## blc parameters

This action is intended as a very simple call on the `blc` tool. The full list of options:

```
Usage
  blc [OPTIONS] [ARGS]

Options
  --exclude               A keyword/glob to match links against. Can be used multiple times.
  --exclude-external, -e  Will not check external links.
  --exclude-internal, -i  Will not check internal links.
  --filter-level          The types of tags and attributes that are considered links.
                            0: clickable links
                            1: 0 + media, iframes, meta refreshes
                            2: 1 + stylesheets, scripts, forms
                            3: 2 + metadata
                            Default: 1
  --follow, -f            Force-follow robot exclusions.
  --get, -g               Change request method to GET.
  --help, -h, -?          Display this help text.
  --input                 URL to an HTML document.
  --host-requests         Concurrent requests limit per host.
  --ordered, -o           Maintain the order of links as they appear in their HTML document.
  --recursive, -r         Recursively scan ("crawl") the HTML document(s).
  --requests              Concurrent requests limit.
  --user-agent            The user agent to use for link checks.
  --verbose, -v           Display excluded links.
  --version, -V           Display the app version.

Arguments
  INPUT                   Alias to --input
```


## Test

There is a broken link in this document as a test:
[A broken link](https://fooasldn.com/)
