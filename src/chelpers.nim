
# Another helper to make a string from a NON null terminated string with a length.
proc `$`(x: string, len: int): string =
  result = newString(len)
  copyMem(addr(result[0]), x, len)
