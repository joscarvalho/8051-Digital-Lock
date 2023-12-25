# 8051-Digital-Lock
Digital Lock for the 8051 Microcontroller implemented in Assembly (A51).

A programmable digital lock with a 4-digit code with an HMI interface using a 7-segment display that actuates a blocking voltage in a GPIO pin when locked.

The following states are available in the system:
- Locked: Lock's initial condition. Blocking voltage is activated. Can only be changed upon inserting a 4-digit numerical code.
- Open: If the key is inserted correctly, the system is unlocked.
- Fail: If the key is incorrect, the system remains locked and in a fault state for 30 seconds. Consecutive failed attempts to unlock add another 30 seconds to the fault state. Upon failing 3 consecutive times, the system is blocked and can only be unlocked with a recovery condition. In this state, a sound alarm is generated using a square wave.

The recovery condition is a backdoor to unlock a blocked system by changing the key and is activated by pressing the LOAD button 40 times.
