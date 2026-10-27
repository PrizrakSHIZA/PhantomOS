-- Use each display's preferred native resolution and refresh rate.
-- `highrr` can choose a low-resolution mode if it exposes a higher refresh rate.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})
