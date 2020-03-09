# How to contribute

**Thank you**, we are really glad that you want to contribute to this project!

SQL Anti-Patterns is all about the collective wisdom of the community and as such we need volunteers like yourself to help fill in the gaps.

Below you can find a couple of guidlines on how to contribute. Please take the time to read through them, it's not that long. ;)

## Submitting an Anti-Pattern

If you have an anti-pattern that you would like to add, here is what you need to do:

File a [Pull Request (PR)](https://github.com/sql-anti-patterns/sql-anti-patterns.github.io/pulls) with your anti-pattern, updating the [README.md](README.md) file in the according section. Always sign off on your commits and provide a clear log message. One-liners are fine for small changes such as typo corrections and similar, but new anti-patterns should have a clear description on why this is an anti-pattern and why it should be considered for inclusion, for example:

```
$ git commit --signoff -m "SELECT * FROM anti-pattern
>
> 'SELECT * FROM' is bad because it does not guarantee
> the correct column amount nor column order."
```

### Testing

Although a lot of anti-patterns appear to be common knowledge amongst database professionals, we really appreciate if you can provide a test case for one or more databases under the [tests](./tests) folder that confirms the anti-pattern. If the anti-pattern is of theoretical or design nature, please take the time to write a clear explanation on it in the README.md itself.

## Disputing an Anti-Pattern
If you disagree with something being an anti-pattern, please let us know! Just head over to the [Issues](https://github.com/sql-anti-patterns/sql-anti-patterns.github.io/issues) and open a new issue explaining why you think that the anti-pattern isn't one and why it should be removed.

Always remember, we like to keep our discussions civilized so please be respectful in your communications. Sometimes an issue for others isn't an issue for you and vice versa and sometimes we may come to the conclusion that we agree to disagree.

Thanks once again!

Gerald & Team