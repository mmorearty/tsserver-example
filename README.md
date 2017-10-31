# Example usage of TypeScript's tsserver

A small example of how to communicate with TypeScript's `tsserver`. This is
deliberately hard-coded and very minimal.  The intent is to give you a starting
point so you can begin to understand the communication protocol.

## To run it

First: `npm install`. That will install all packages listed in `package.json`
-- most importantly, the `typescript` package.

Then, to actually run it: `./run.sh`

Basically all that does is `tsserver < tsserver.input`, but with the additional
complication that since `tsserver` requires full paths in the filenames it
receives, we first have to do a bit of preprocessing on `tsserver.input` to put
full paths in there.

`tsserver.input` is a sequence of commands that will be sent to `tsserver`, one
per line (which is the format that tsserver requires).

## What it does

`tsserver.input` sends these commands to `tsserver`:

* An `"open"` command to tell `tsserver` to open `example.ts`. `tsserver` does
  not send back a `"response"` to this command, but this does trigger two
  `"event"`s.
* A `"quickinfo"` command to ask for info about the `console` part of
  `console.log`. `tsserver` sends back a short response. The `"displayString"`
  portion of the response is `"var console: Console"`, which is exactly the
  same thing you would see if you opened example.ts in Visual Studio Code and
  hovered over `console`.
* A `"getApplicableRefactors"` command for line two of `example.ts`. The list
  of responses is the same list you would see if you opened example.ts in
  Visual Studio Code, selected line two of the file, and clicked on the "Show
  Fixes" lightbulb.
* A `"getEditsForRefactor"` command for line two of `example.ts`, asking it
  what edits are needed to the source code in order to actually apply the
  "Extract function into global scope" refactor. The response is the same list
  of edits that Visual Studio Code makes if you apply that refactoring.

## The output

This is the output, modified so that the JSON is pretty-printed.

Note that when you try it yourself with `./run.sh`, you will see that each
response is preceded by a `Content-Length:` header, followed by `\r\n\r\n`.

In response to the `"open"` command, these two events come back (note, these
are `"type": "event"`, not `"type": "response"` -- there is no actual response
to the `"open"` command):

```json
{
  "seq": 0,
  "type": "event",
  "event": "telemetry",
  "body": {
    "telemetryEventName": "projectInfo",
    "payload": {
      "projectId": "a77a57adbab7279c51c83282b074c517",
      "fileStats": {
        "js": 0,
        "jsx": 0,
        "ts": 1,
        "tsx": 0,
        "dts": 1
      },
      "compilerOptions": {},
      "typeAcquisition": {
        "enable": false,
        "include": false,
        "exclude": false
      },
      "extends": false,
      "files": false,
      "include": false,
      "exclude": false,
      "compileOnSave": false,
      "configFileName": "tsconfig.json",
      "projectType": "configured",
      "languageServiceEnabled": true,
      "version": "2.6.1"
    }
  }
}

{
  "seq": 0,
  "type": "event",
  "event": "configFileDiag",
  "body": {
    "triggerFile": "/Users/mikemorearty/src/typescript/tsserver-example/example.ts",
    "configFile": "/Users/mikemorearty/src/typescript/tsserver-example/tsconfig.json",
    "diagnostics": []
  }
}
```

In response to the `"quickinfo"` command, this response comes back:

```json
{
  "seq": 0,
  "type": "response",
  "command": "quickinfo",
  "request_seq": 1,
  "success": true,
  "body": {
    "kind": "var",
    "kindModifiers": "declare",
    "start": {
      "line": 2,
      "offset": 5
    },
    "end": {
      "line": 2,
      "offset": 12
    },
    "displayString": "var console: Console",
    "documentation": "",
    "tags": []
  }
}
```

In response to the `"getApplicableRefactors"` command, this response comes back:

```json
{
  "seq": 0,
  "type": "response",
  "command": "getApplicableRefactors",
  "request_seq": 2,
  "success": true,
  "body": [
    {
      "name": "Extract Symbol",
      "description": "Extract function",
      "actions": [
        {
          "description": "Extract to inner function in function 'x'",
          "name": "function_scope_0"
        },
        {
          "description": "Extract to function in global scope",
          "name": "function_scope_1"
        }
      ]
    }
  ]
}
```

In that response, notice that the `"body"` has `"name": "Extract Symbol"`, and
inside that, one of the `"actions"` has `"name": "function_scope_1"`. If you
look at `tsserver.input`, you will see both of those in the next command that I
send, which is `"getEditsForRefactor"`.

In response to the `"getEditsForRefactor"` command, this response comes back:

```json
{
  "seq": 0,
  "type": "response",
  "command": "getEditsForRefactor",
  "request_seq": 3,
  "success": true,
  "body": {
    "renameLocation": {
      "line": 2,
      "offset": 5
    },
    "renameFilename": "/Users/mikemorearty/src/typescript/tsserver-example/example.ts",
    "edits": [
      {
        "fileName": "/Users/mikemorearty/src/typescript/tsserver-example/example.ts",
        "textChanges": [
          {
            "start": {
              "line": 2,
              "offset": 5
            },
            "end": {
              "line": 2,
              "offset": 20
            },
            "newText": "newFunction();"
          },
          {
            "start": {
              "line": 3,
              "offset": 2
            },
            "end": {
              "line": 3,
              "offset": 2
            },
            "newText": "\n\nfunction newFunction() {\n    console.log(1);\n}\n"
          }
        ]
      }
    ]
  }
}
```

