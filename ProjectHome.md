Chimp is permission based filtering component for Adobe Flex and AIR.  Applications implement Chimp by adding metadata within the Flex UIComponents.  Based on the metadata it will remove components completely, enable/disable, and update visibility.

### Quick Setup: ###
1) Download and add the chimp.swc to your project library
<br>
2) Add compiler argument to keep necessary metadata:<br>
<pre><code>-locale en_US -keep-as3-metadata+=Protected <br>
</code></pre>
3) Load the Chimp in your application.  The Chimp must be loaded but before children are added because they are tracked with an event listener on the add to stage system event:<br>
<pre><code>Chimp.load(perms);<br>
</code></pre>
4) Add metadata to your Flex components:<br>
<pre><code>[Protected(permissions="ROLE_ADMIN",notInPermissionAction="removeChild",componentId="this")]<br>
[Protected(permissions="ROLE_UPDATE",inPermissionAction="enable",componentId="updateButton")]        <br>
</code></pre>

<br>
<h3><i><code>[</code>Protected<code>]</code></i> Metadata properties:</h3>
<ul>
<li><i><b>permissions:</b></i> A comma delimited string of the permissions to use for the protected operation.<br>
<li><i><b>componentId:</b></i>  This is the string name of the component that is to be protected.  This can be omitted or set to ‘this’ for current component.  To protect a child, set the componentId to the ‘id’ string of the component.<br>
<li><i><b>notInPermissionAction:</b></i> If the user does not have any of the permissions, then the action provided is performed (use only this or inPermissionAction – not both).<br>
<li><i><b>inPermissionAction:</b></i> If the user has any of the permissions, then the action provided is performed (use only this or notInPermissionAction – not both).<br>
<br>
<br>
<i>Possible actions:</i>
<ul>
<blockquote><li><i>removeChild:</i> Removes the component completely, by calling ‘comp.parent.removeChild()”<br>
<li><i>removeFromLayout: </i> Use the includeInLayout property to remove components<br>
<li><i>invisible:</i> Sets the comp.visible property to false<br>
<li><i>visable:</i> Sets the comp.visible property to true<br>
<li><i>disable:<i> Sets the comp.enable property to false<br>
<li><i>enable:</i> Sets the comp.enable property to true