defmodule ValentineWeb.WorkspaceLive.Threat.Components.TextInputComponent do
  use ValentineWeb, :live_component
  use PrimerLive

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.styled_html>
        <h3>{@context.title}</h3>
        <p>{@context.description}</p>

        <.text_input
          id={"#{@id}-#{@active_field}"}
          name={"threat-#{@active_field}"}
          phx-keyup="update_field"
          value={@current_value}
        >
          <:trailing_action is_visible_with_value>
            <.button
              is_close_button
              aria-label="Clear"
              onclick={"document.querySelector('[name=threat-#{@active_field}]').value=''"}
            >
              <.octicon name="x-16" />
            </.button>
          </:trailing_action>
        </.text_input>
        <div class="clearfix">
          <div class="float-left col-6">
            <%= if @context.examples && length(@context.examples) > 0 do %>
              <h4>Generic examples:</h4>
              <ul>
                <%= for example <- @context.examples do %>
                  <li>
                    <.link phx-click="update_field" phx-value-value={example}>
                      {example}
                    </.link>
                  </li>
                <% end %>
              </ul>
            <% end %>
          </div>
          <div class="float-left col-6">
            <%= if @dfd_examples && length(@dfd_examples) > 0 do %>
              <h4>From data flow diagram:</h4>
              <ul>
                <%= for example <- @dfd_examples do %>
                  <li>
                    <.link phx-click="update_field" phx-value-value={example}>
                      {example}
                    </.link>
                  </li>
                <% end %>
              </ul>
            <% end %>
          </div>
        </div>
      </.styled_html>
    </div>
    """
  end
end
