angular.module('coffeeshop').service "storage", ($location, $q, $rootScope)->
	products = null

	base = "#{$location.protocol()}://#{$location.host()}:#{$location.port()}/"
	runtime = new JEFRi.Runtime "#{base}context.json"
	loading = $q.defer()

	storage =
		get: ->
		save: ->
		runtime: runtime
		ready: loading.promise

	runtime.ready.then ->
		t = new window.JEFRi.Transaction()
		t.add _type: 'Product'
		s = new window.JEFRi.Stores.PostStore({remote: base, runtime})

		s.execute('get', t)
		.then (list)->
			if list.entities.length
				runtime.expand list.entities
				products = runtime.find('Product')
			else
				throw new Exception 'Product not found.'
		.catch (e)->
			products = [runtime.build('Product', {'name':'Product Name'})]
		.finally ->
			storage.get = -> products
			storage.save = ->
				t = new window.JEFRi.Transaction()
				t.add product for product in products
				s = new window.JEFRi.Stores.PostStore({remote: base, runtime})
				s.execute 'persist', t

			loading.resolve products # Why doesn't resolving $q trigger a digest?
			$rootScope.$digest()
			
	.catch (e)->
		console.error "Couldn't load context!"
		console.error e.message, e
	storage
