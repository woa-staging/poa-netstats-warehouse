defmodule POABackend.CustomHandler do

  alias POABackend.Protocol.Message
  alias POABackend.Metric

  @moduledoc """
  A Custom Handler is responsible of handling data sent from Agents (i.e. REST over HTTP, WebSockets...) "speaking" the POA Protocol.

  The main responsability is getting calls from Agents, transform the data into a [POABackend.Protocol.Message](POABackend.Protocol.Message.html#content) 
  Struct and sending it to the receivers.

  ### Writing your custom Handler

  You must to _use_ the POABackend.CustomHandler module. That will requires you to implement the function `child_spec/1` which will be
  called from the `POABackend.CustomHandler.Supervisor` and it must returns the child spec for the process you are going to spawn.

      defmodule MyHandler do
        use POABackend.CustomHandler

        def child_spec(options) do
          Plug.Adapters.Cowboy.child_spec(scheme: options[:scheme], plug: POABackend.CustomHandler.Rest.Router, options: [port: options[:port]])
        end

      end

  In this example we are initializing our CustomHandler for REST requests using the Cowboy Plug and defining the endpoints in the `POABackend.CustomHandler.Rest.Router`
  module.

  ### Configuring the handlers in the config file

  So far we have created a Custom Handler but we didn't tell `poa_backend` to start it. In order to do it we have to define the new Handler in
  the config file.

      config :poa_backend, 
       :custom_handlers,
       [
         {:rest_custom_handler, POABackend.CustomHandler.Rest, [port: 4002]}
       ]
  
  Inside the `:custom_handlers` list we define the handlers we want to start. Each Handler is defined in a triple tuple where the first argument
  is the id for that handler, the second one is the Elixir module which implements the CustomHandler behaviour and the third one is a list for arguments
  which will be passed to the `child_spec/1` function as a parameter

  ### Helpful functions

  This module also define some helpful functions:

  - send_to_receivers/1: This function will publish the incomming message to the appropiate metric type (Data Type). A Custom Handler must call it when it wants to dispatch a message.
  - publish_inactive/1: Will publish an inactive message to all the metrics in the system. A Custom Handler must call it when detects if a client is disconnected or/and inactive

  """

  @doc """
  This function will be called from the `POABackend.CustomHandler.Supervisor` in order
  to get the child specification for start the custom handler process.
  """
  @callback child_spec(options :: list()) :: :supervisor.child_spec()

  defmacro __using__(_opts) do
    quote do
      @behaviour POABackend.CustomHandler
    end
  end

  @doc """
  This function dispatches the given Message to the appropiate receivers based on the Data Type (ie :ethereum_metric).

  The mapping between Data Types and Receivers is done in the config file.

  _Note_ the message must be a [POABackend.Protocol.Message](POABackend.Protocol.Message.html) struct
  """
  @spec send_to_receivers(Message.t) :: :ok
  def send_to_receivers(%Message{} = message) do
    Metric.add(message.data_type, message)
  end

  @doc """
  Publish an inactive message to all the metrics defined  in the config file.

  A Custom Handler must call this explicity when detecting if a client is inactive for a period of time
  """
  def publish_inactive(agent_id) do
    Metric.broadcast({:inactive, agent_id})
  end
end