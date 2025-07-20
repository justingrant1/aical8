web: cd backend && bundle exec rails server -b 0.0.0.0 -p $PORT
worker: cd backend && bundle exec sidekiq
release: cd backend && bundle exec rails db:migrate
