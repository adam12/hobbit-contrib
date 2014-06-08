require 'helper'

scope Hobbit::Filter do
  scope 'basic specs' do
    setup do
      mock_app do
        include Hobbit::Filter

        before do
          env['hobbit.before'] = 'this is before'
        end

        get '/' do
          'GET /'
        end

        after do
          env['hobbit.after'] = 'this is after'
        end
      end
    end

    %w(after before).each do |kind|
      str = <<EOS
    scope '::#{kind}' do
      test do
        p = Proc.new { 'do something' }
        app = mock_app do
          include Hobbit::Filter
          #{kind}('', &p)
        end

        assert app.to_app.class.filters[:#{kind}].size == 1
        assert app.to_app.class.filters[:#{kind}].first[:block].call == p.call
      end
    end

    scope 'when a filter matches' do
      test "calls the filters' block" do
        get '/'
        assert last_response.ok?
        assert last_request.env.include? 'hobbit.#{kind}'
        assert last_request.env['hobbit.#{kind}'] == 'this is #{kind}'
      end
    end
EOS
      instance_eval str
    end

    scope '::filters' do
      test 'returns a Hash' do
        assert app.to_app.class.filters.kind_of? Hash
      end
    end

    scope '::compile_filter' do
      def block
        Proc.new { |env| [200, {}, []] }
      end

      test 'compiles /' do
        path = '/'
        route = app.to_app.class.send :compile_filter, path, &block
        assert route[:block].call({}) == block.call({})
        assert route[:compiled_path].to_s == /^\/$/.to_s
      end

      test 'compiles with .' do
        path = '/route.json'
        route = app.to_app.class.send :compile_filter, path, &block
        assert route[:block].call({}) == block.call({})
        assert route[:compiled_path].to_s == /^\/route.json$/.to_s
      end

      test 'compiles with -' do
        path = '/hello-world'
        route = app.to_app.class.send :compile_filter, path, &block
        assert route[:block].call({}) == block.call({})
        assert route[:compiled_path].to_s == /^\/hello-world$/.to_s
      end

      test 'compiles with params' do
        path = '/hello/:name'
        route = app.to_app.class.send :compile_filter, path, &block
        assert route[:block].call({}) == block.call({})
        assert route[:compiled_path].to_s == /^\/hello\/([^\/?#]+)$/.to_s

        path = '/say/:something/to/:someone'
        route = app.to_app.class.send :compile_filter, path, &block
        assert route[:block].call({}) == block.call({})
        assert route[:compiled_path].to_s == /^\/say\/([^\/?#]+)\/to\/([^\/?#]+)$/.to_s
      end

      test 'compiles with . and params' do
        path = '/route/:id.json'
        route = app.to_app.class.send :compile_filter, path, &block
        assert route[:block].call({}) == block.call({})
        assert route[:compiled_path].to_s == /^\/route\/([^\/?#]+).json$/.to_s
      end
    end

    test 'calls before and after filters' do
      get '/'
      assert last_response.ok?
      assert last_request.env.include? 'hobbit.before'
      assert last_request.env['hobbit.before'] == 'this is before'
      assert last_request.env.include? 'hobbit.after'
      assert last_request.env['hobbit.after'] == 'this is after'
    end
  end

  scope 'filters with parameters' do
    setup do
      mock_app do
        include Hobbit::Filter

        before '/:name' do
          env['hobbit.before'] = 'this is before'
        end

        after '/:name' do
          env['hobbit.after'] = 'this is after'
        end

        get('/:name') { env['hobbit.before'] }
      end
    end

    test 'calls the before and after filters' do
      get '/hobbit'
      assert last_response.ok?
      assert last_request.env.include? 'hobbit.before'
      assert last_request.env['hobbit.before'] == 'this is before'
      assert last_request.env.include? 'hobbit.after'
      assert last_request.env['hobbit.after'] == 'this is after'
    end
  end

  scope 'when multiple filters are declared' do
    setup do
      mock_app do
        include Hobbit::Filter

        before do
          env['hobbit.before'] = 'this will match'
        end

        before '/' do
          env['hobbit.before'] = 'this wont match'
        end

        after do
          env['hobbit.after'] = 'this will match'
        end

        after '/' do
          env['hobbit.after'] = 'this wont match'
        end

        get('/') { 'GET /' }
      end
    end

    test 'calls the first that matches' do
      get '/'
      assert last_response.ok?
      assert last_request.env.include? 'hobbit.before'
      assert last_request.env['hobbit.before'] == 'this will match'
      assert last_request.env.include? 'hobbit.after'
      assert last_request.env['hobbit.after'] == 'this will match'
    end
  end

  scope 'when a before filter redirects the response' do
    setup do
      mock_app do
        include Hobbit::Filter

        before do
          response.redirect '/goodbye' unless request.path_info == '/goodbye'
        end

        get '/' do
          'hello world'
        end

        get '/goodbye' do
          'goodbye world'
        end
      end
    end

    test 'redirects on before filters' do
      get '/'
      assert last_response.redirection?
      follow_redirect!
      assert last_response.ok?
      assert last_response.body =~ /goodbye world/
    end
  end

  scope 'when halting in a before filter' do
    setup do
      mock_app do
        include Hobbit::Filter

        before do
          halt 401
        end

        get '/' do
          'hello world'
        end
      end
    end

    test 'does not execute the route' do
      get '/'
      assert last_response.status == 401
      assert last_response.body.empty?
    end
  end

  scope 'when halting in a route' do
    setup do
      mock_app do
        include Hobbit::Filter

        before do
          response.headers['Content-Type'] = 'text/plain'
        end

        after do
          response.headers['Content-Type'] = 'application/json'
        end

        get '/' do
          halt 401, 'Unauthenticated'
        end
      end
    end

    test 'does not execute the after filter' do
      get '/'
      assert last_response.status == 401
      assert last_response.headers.include? 'Content-Type'
      assert last_response.headers['Content-Type'] == 'text/plain'
      assert last_response.body == 'Unauthenticated'
    end
  end

  scope 'when halting in an after filter' do
    setup do
      mock_app do
        include Hobbit::Filter

        after do
          halt 401
        end

        get '/' do
          'hello world'
        end
      end
    end

    test 'does not execute the route' do
      get '/'
      assert last_response.status == 401
      assert last_response.body == 'hello world'
    end
  end
end
