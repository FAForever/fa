- Add the `Unit.OnBeforeTransfer` and `Unit.OnAfterTransfer` hooks, which `TransferUnitsOwnership` calls so that a unit class can carry state over a transfer (#7442).

- Add `Unit.AddTransferCallback`, which lets a unit carry state that isn't part of its class over a transfer, such as a mod's or a buff's (#7442).
