# TypedNetwork

Type-safe, async/await-first networking for iOS.

Instead of defining APIs as enum targets, TypedNetwork models each request as a strongly-typed Endpoint that knows its Response and Error.

## Installation

Swift Package Manager:

https://github.com/tuusuario/TypedNetwork

## Example

```swift
let user = try await client.send(GetUser(id: 1))
