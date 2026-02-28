# dart-drmem

Create Dart clients for the DrMem Control System.

## Introduction

The DrMem Control System is a tiny, personal control system that can be used
to simply control lights in your home or can support more advanced forms of
control. Although DrMem can be configured to run as a standalone process, a
more useful configuration is to enable a GraphQL API. This package is used to
make Dart (and Flutter) clients that can interact with DrMem nodes.

## Features

Supports the full DrMem GraphQL API:

- Query a node's configuration
  - What drivers are configured
  - What devices are defined
  - What logic blocks are defined
- Receive a stream of devices' updates
- Set devices to new value

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder. 

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
