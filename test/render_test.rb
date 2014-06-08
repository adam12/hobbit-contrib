require 'tilt/erubis'

require 'helper'

scope Hobbit::Render do
  setup do
    mock_app do
      include Hobbit::Render

      def views_path
        File.expand_path '../fixtures/render/views/', __FILE__
      end

      def name
        'Hobbit'
      end

      get('/') { render 'index' }
      get('/partial') { partial 'partial' }
      get('/using-context') { render 'hello' }
      get('/without-layout') { render '_partial', {}, layout: false }
    end
  end

  scope '#default_layout' do
    test 'defaults to application.erb' do
      assert app.to_app.default_layout == "#{app.to_app.layouts_path}/application.erb"
    end
  end

  scope '#find_template' do
    test 'returns a template path' do
      assert app.to_app.find_template('index') == "#{app.to_app.views_path}/index.#{app.to_app.template_engine}"
    end
  end

  scope '#layouts_path' do
    test 'returns the path to the layouts directory' do
      assert app.to_app.layouts_path == "#{app.to_app.views_path}/layouts"
    end
  end

  scope '#partial' do
    test 'renders a template without a layout' do
      get '/partial'
      assert last_response.ok?
      assert last_response.body !~ /From application.erb/
      assert last_response.body =~ /Hello World!/
    end
  end

  scope '#render' do
    test 'renders a template (using a layout)' do
      get '/'
      assert last_response.ok?
      assert last_response.body =~ /From application.erb/
      assert last_response.body =~ /Hello World!/
    end

    test 'renders a template (not using a layout)' do
      get '/without-layout'
      assert last_response.ok?
      assert last_response.body !~ /From application.erb/
      assert last_response.body =~ /Hello World!/
    end

    test 'renders a template using the app as context' do
      get '/using-context'
      assert last_response.ok?
      assert last_response.body =~ /From application.erb/
      assert last_response.body =~ /Hello Hobbit!/
    end
  end

  scope '#template_engine' do
    test 'defaults to erb' do
      assert app.to_app.template_engine == 'erb'
    end
  end

  scope '#views_path' do
    test 'returns the path to the views directory' do
      assert app.to_app.views_path == File.expand_path('../fixtures/render/views', __FILE__)
    end

    test 'defaults to "views"' do
      mock_app do
        include Hobbit::Render
      end

      assert app.to_app.views_path == 'views'
    end
  end
end
