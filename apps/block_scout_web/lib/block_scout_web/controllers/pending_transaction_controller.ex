defmodule BlockScoutWeb.PendingTransactionController do
  use BlockScoutWeb, :controller

  import BlockScoutWeb.Chain, only: [paging_options: 1, next_page_params: 3, split_list_by_page: 1]

  alias BlockScoutWeb.TransactionView
  alias Explorer.Chain
  alias Phoenix.View

  def index(conn, %{"type" => "JSON"} = params) do
    full_options =
      Keyword.merge(
        [
          necessity_by_association: %{
            [from_address: :names] => :optional,
            [to_address: :names] => :optional
          }
        ],
        paging_options(params)
      )

    {transactions, next_page} = get_pending_transactions_and_next_page(full_options)

    next_page_url =
      case next_page_params(next_page, transactions, params) do
        nil ->
          nil

        next_page_params ->
          pending_transaction_path(
            conn,
            :index,
            Map.delete(next_page_params, "type")
          )
      end

    json(
      conn,
      %{
        items:
          Enum.map(transactions, fn transaction ->
            View.render_to_string(
              TransactionView,
              "_tile.html",
              transaction: transaction
            )
          end),
        next_page_path: next_page_url
      }
    )
  end

  def index(conn, _params) do
    render(conn, "index.html", current_path: current_path(conn))
  end

  defp get_pending_transactions_and_next_page(options) do
    transactions_plus_one = Chain.recent_pending_transactions(options)
    split_list_by_page(transactions_plus_one)
  end
end
