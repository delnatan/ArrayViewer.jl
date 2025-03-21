module ArrayViewer

using GLMakie

export imshow


function imshow(arr::AbstractArray{T,N}; colormap::Symbol=:viridis) where {T,N}

    figsize = (600,600)
    slider_column_width = 5
    toggle_column_start = slider_column_width + 1
    
    if ndims(arr) == 2
        fig = Figure(size=figsize)

        # data inspector
        ax = GLMakie.Axis(fig[1, 1:7], aspect=DataAspect())

        # Create DataInspector and Toggle button for pixel inspector
        inspector = DataInspector(ax)
        toggle_gl = GridLayout(fig[2, toggle_column_start:8], tellwidth=false)
        Label(toggle_gl[1,1], "inspector")
        inspect_toggle = Toggle(toggle_gl[1,2], active=true)
                
        hm = heatmap!(ax, arr, colormap=colormap)
        cb = Colorbar(fig[1, 8], hm)

        # toggle plot inspectability on/off directly rather than
        # modifying the inspector (bug? DataInspector has no 'enabled' field)
        on(inspect_toggle.active) do val
            hm.inspectable[] = val
            inspect_toggle.active[] || return
        end

        # reset to full view
        keys_events = fig.scene.events.keyboardbutton
        on(keys_events) do key
            if key.action == Keyboard.press && key.key == Keyboard.a
                ny, nx = size(arr)
                autolimits!(ax)
            end
        end

        
        return fig
        
    elseif ndims(arr) > 2
        
        fig = Figure(size=figsize)

        # get dimensions beyond the last two axes
        slider_dims = [size(arr, i) for i in 1:(N - 2)]
        slice_indices = [Observable(1) for i in 1:(N - 2)]

        # for every 'extra' dimension new sliders are made below
        # sliders only use 5/8 of the window width
        for (i, dim_size) in enumerate(slider_dims)
            slider = Slider(fig[end+1, 1:4], range=1:dim_size, startvalue=1)
            # connect observable to slider
            connect!(slice_indices[i], slider.value)
        end

        current_slice = Observable(view(arr, ones(Int, N-2)..., :, :))

        # connect callback to slider observables
        for obs in slice_indices
            on(obs) do _
                idx = [index[] for index in slice_indices]
                current_slice[] = view(arr, idx..., :, :)
            end
        end
        
        ax = GLMakie.Axis(fig[1, 1:7], aspect=DataAspect())

        # Create DataInspector and Toggle button for pixel inspector
        inspector = DataInspector(ax)
        toggle_gl = GridLayout(fig[2, toggle_column_start:8], tellwidth=false)
        Label(toggle_gl[1,1], "inspector")
        inspect_toggle = Toggle(toggle_gl[1,2], active=true)

        vmin = Observable(minimum(arr))
        vmax = Observable(maximum(arr))
        gamma = Observable(1.0)

        gamma_scaler = lift(gamma) do γ
            ReversibleScale(
                x -> sign(x) * abs(x)^(1/γ), # forward transform
                x -> sign(x) * abs(x)^γ, # inverse transform
            )
        end
        
        # now create the display min/max/gamma adjustment inputs
        dispctrl_gl = GridLayout(fig[3, slider_column_width:8], tellwidth=false)
        vmin_input = Textbox(dispctrl_gl[1, 2], placeholder="$(vmin[])", width=60, height=20, fontsize=9)
        vmax_input = Textbox(dispctrl_gl[2, 2], placeholder="$(vmax[])", width=60, height=20, fontsize=9)
        gamma_input = Textbox(dispctrl_gl[3, 2], placeholder="$(gamma[])", width=60, height=20, fontsize=9)

        Label(dispctrl_gl[1,1], "min")
        Label(dispctrl_gl[2,1], "max")
        Label(dispctrl_gl[3,1], "gamma")
        
        hm = heatmap!(
            ax, current_slice, colormap=colormap,
            colorrange=@lift(($vmin, $vmax)),
            colorscale=gamma_scaler
        )
        
        # toggle plot inspectability on/off directly rather than
        # modifying the inspector (bug? DataInspector has no 'enabled' field)
        on(inspect_toggle.active) do val
            hm.inspectable[] = val
            inspect_toggle.active[] || return
        end

        # add colorbar
        cb = Colorbar(fig[1, 8], hm, size=8)

        # reset to full view
        keys_events = fig.scene.events.keyboardbutton
        on(keys_events) do key
            if key.action == Keyboard.press && key.key == Keyboard.a
                ny, nx = size(current_slice[])
                autolimits!(ax)
            end
        end

        # adjustment of min/max/gamma, update the observables
        on(vmin_input.stored_string) do s
            vmin[] = parse(Float64, s)
        end

        on(vmax_input.stored_string) do s
            vmax[] = parse(Float64, s)
        end

        on(gamma_input.stored_string) do s
            gamma[] = parse(Float64, s)
        end
        
        return fig
        
    end
    
end

end # module ArrayViewer
