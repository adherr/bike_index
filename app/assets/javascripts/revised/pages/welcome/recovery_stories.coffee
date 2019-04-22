class BikeIndex.RecoveryStories extends BikeIndex
  constructor: ->
    $recovery_stories_containers = $('.recovery-stories-container')
    for recovery_stories_container in $recovery_stories_containers
      $recovery_stories_container = $(recovery_stories_container)
      num_slides = $recovery_stories_container.data('stories-count')
      $recovery_stories_containers.slick
        lazyLoad: 'ondemand'
        slidesToShow: num_slides
        vertical: true
