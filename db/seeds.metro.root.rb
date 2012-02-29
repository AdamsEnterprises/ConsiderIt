admin = User.new(
  :name => 'Metro Admin',
  :email => 'considerit481@googlegroups.com',
  :password   => 'password',
  :password_confirmation => 'password'
)

admin.skip_confirmation!
admin.save

o0 = Option.create!(
  :name => 'Proposal requiring all buses to stop at the bus stop pole.',
  :short_name => 'Stopping at bus stop pole',
  :description => 'To prevent Metro buses from accidentally passing a rider waiting to board, buses should always stop at the bus stop pole if a rider is waiting - even if the bus already boarded riders farther back.',
  :domain => 'Metro',
  :domain_short => 'Metro',
  :category => 'Proposal',
  :designator => '1',
  :long_description => '<b>Current Policy</b> <br> 
    At bus stops that serve multiple routes, several buses often arrive at 
    the same time. Under the current policy, the second bus to arrive is not 
    required to stop again at the pole, but the third and subsequent buses are.
    <br> <br> 
    <b>Proposal</b> <br>
    Under the proposed change, all buses will be required to stop at the pole, 
    including the second bus.
    <p>' )

p0 = Point.create!(
  :option => o0,
  :user => admin,
  :is_pro => true,
  :nutshell => 'Requiring all buses to stop at the pole ensures that riders there will not miss their bus.',
:text => '', :published => true
)

p1 = Point.create!(
  :option => o0,
  :user => admin,
  :is_pro => false,
  :nutshell => 'At stops where many buses are arriving continuously, this change may cause congestion and backups among buses.',
:text => '', :published => true
)

o1 = Option.create!(
  :name => 'Proposal to phase out Bus Identifier Tool.',
  :short_name => 'Phasing Out Bus Identifier Tool',
  :description => 'Metro will no longer support the Bus Identifier Tool as an option for blind and low-vision riders who cannot read the route number on a bus. Currently, this spiral-bound flipbook allows riders to hold up the desired route number as a signal to the bus driver to stop for them.',
  :domain => 'Metro',
  :domain_short => 'Metro',
  :category => 'Proposal',
  :designator => '2',
  :long_description => '<b>Current Policy</b> <br> 
    Metro provides the Bus Identifier flipbook as an option for blind and 
    low-vision riders to ensure that they are not passed by their bus while 
    they wait. This tool consists of three spiral bound digits that can be 
    flipped through in order to form the bus number. Each digit has Braille 
    printing for riders.
    <br> <br> 
    <b>Proposal</b> <br>
    Under the proposed change, the Bus Identifier Tool will be phased out.
    <p>' )

p2 = Point.create!(
  :option => o1,
  :user => admin,
  :is_pro => true,
  :nutshell => 'The Bus Identifier Tool provided a standard, officially supported way for blind and low-vision riders to identify the bus they want.',
:text => '', :published => true
)

p3 = Point.create!(
  :option => o1,
  :user => admin,
  :is_pro => false,
  :nutshell => 'Some blind and low-vision riders feel that the Bus Identifer Tool is conspicuous and stigmatizing.',
:text => '', :published => true
)

