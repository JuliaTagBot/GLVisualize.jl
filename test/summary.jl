using GLAbstraction, GLWindow, GLVisualize
using FileIO, GeometryTypes, Reactive, Images
using Colors, Plots

# These are allowed to fail, since they depend on not installed packages
allowed_to_fail = ("mesh_edit.jl", "billiard.jl")

allowed_failures = filter(config.attributes) do k, dict
    !dict[:success] && (basename(k) in allowed_to_fail)
end
failures = filter(config.attributes) do k, dict
    !dict[:success] && !(basename(k) in allowed_to_fail)
end
successfull = filter(config.attributes) do k, dict
    dict[:success]
end

window = GLWindow.rootscreen(config.window)

resize!(window, 800, 700)

function is_installed(pkgstr::AbstractString)
    try
        Pkg.installed(pkgstr) === nothing ? false: true
    catch
        false
    end
end

empty!(window)

area = Signal(SimpleRectangle(0, 0, 800, 300))
area2 = Signal(SimpleRectangle(0, 300, 800, 400))

plot_screen = Screen(window, name=:plots, area=area)
glvis_screen = Screen(window, name=:glvis, area=area2)
GLVisualize.add_screen(plot_screen) # make main screen for Plots

using Plots; glvisualize(size=(800, 300))
ystat = [length(failures), length(allowed_failures), length(successfull)]
failur_plt = bar(
    ["failures", "allowed failures", "passed"],
    ystat,
    markerstrokewidth=0f0, leg=false,
    title="Test Statistic",
    color=[RGBA(0.8, 0.1, 0.2, 0.6), RGBA(0.8, 0.6, 0.1, 0.6),  RGBA(0.1, 0.5, 0.4, 0.6)],
    ylabel="number of tests",
    hover=map(string, ystat)
)
benchmarks = Vector{Float64}[]
benchmark_names = String[]
for (k,v) in successfull
    if haskey(v, :timings)
        push!(benchmark_names, basename(k))
        push!(benchmarks, v[:timings])
    end
end
benchplot = scatter(
    1:length(benchmarks), map(first, benchmarks),
    ms=5, color=RGBA(0.99f0, 0.01f0, 0.4f0, 0.5f0),
    hover=benchmark_names, leg=true,
    label="first run",
    title="Benchmark",
    ylabel="Time in Seconds",
    markerstrokewidth=0f0,
)
benchx = Float64[]
benchy = Float64[]
for (i, elem) in enumerate(benchmarks)
    append!(benchx, fill(i, length(elem)-1))
    append!(benchy, elem[2:end])
end
scatter!(
    benchx, benchy,
    ms=1, shape=:square,
    markerstrokewidth=0f0,
    label="remaining runs"
)
plot(benchplot, failur_plt)
gui()

success_thumbs = Matrix{RGB{U8}}[]
names = String[]
for (k, dict) in successfull
    if haskey(dict, :thumbnail)
        push!(success_thumbs, rotl90(dict[:thumbnail]))
        push!(names, basename(k))
    end
end
rows = 11
len = length(success_thumbs)-1
w = 64
positions = Point2f0[((i%rows)*w*1.05, div(i, rows)*w*1.05) for i=0:len]
positions = positions .+ Point2f0(w/2, 0)

imgs = visualize(
    (success_thumbs, positions),
    scale=Vec2f0(w), stroke_width=2f0
)
_view(imgs, glvis_screen)

Plots.hover(imgs, names, glvis_screen)
renderloop(window)

if !isempty(failures)
    error("Tests not passed with $(length(failures)) failures")
end
