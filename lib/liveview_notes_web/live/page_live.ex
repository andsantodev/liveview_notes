defmodule LiveviewNotesWeb.PageLive do
  use LiveviewNotesWeb, :live_view

  # Esta chamada faz com que cada usuário que visite a página
  # esteja “assinado” ao novo topic pub/sub published_notes.
  # Este topic será usado para a propagação de novas mensagens.
  @topic "published_notes"

  # renderizar via template
  @impl true
  def mount(_params, _session, socket) do
    LiveviewNotesWeb.Endpoint.subscribe(@topic)
    {:ok, assign(socket, note_text: "", draft_notes: [], published_notes: [], error: "")}
  end

  # evento com regra de limite de caracteres
  @impl true
  def handle_event("change_note_text", %{"note_text" => note_text}, socket) do
    case String.length(note_text) do
      50 ->
        {:noreply, assign(socket, error: "limite atingido")}
      n when n > 50 ->
        {:noreply, assign(socket, error: "limite atingido")}
      _ ->
        {:noreply, assign(socket, note_text: note_text, error: "")}
    end
  end

  # criação de nota
  @impl true
  def handle_event("create_note", %{"note_text" => note_text}, socket) do
    {:noreply, assign(socket, draft_notes: [note_text | socket.assigns.draft_notes])}
  end

  # evento que vai publicar as notas na nossa tela
  @impl true
  def handle_event("publish", %{"note" => note}, socket) do
    Phoenix.PubSub.broadcast!(LiveviewNotes.PubSub, @topic, {:update, note})
    {:noreply, socket}
  end

  # evento que vai publicar na tela dos outros usuários
  @impl true
  def handle_info({:update, note} = _info, socket) do
    {:ok, date} = DateTime.now("Etc/UTC")
    pub_note = %{
      title: note,
      published_at: date
    }
    socket =
      socket
      |> assign(draft_notes: Enum.filter(socket.assigns.draft_notes, fn n -> n != note end))
      |> assign(published_notes: [pub_note | socket.assigns.published_notes])
    {:noreply, socket}
  end
end
