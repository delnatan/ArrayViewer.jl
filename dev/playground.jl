using Revise
using ArrayViewer

Revise.revise()

test_array = randn(Float32, (30, 10, 128, 128))

fig = imshow(test_array)

display(fig)

