


# Install pre-push hook

Bash

```bash
echo "$PWD" & ln -s $PWD/pre-push.sh .git/hooks/pre-push
```

For users of the Fish shell

```fish
echo "$PWD"; and ln -s {$PWD}/pre-push.sh .git/hooks/pre-push
```

